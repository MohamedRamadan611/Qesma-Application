package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.domain.Expense;
import app.qesma.domain.Member;
import app.qesma.engine.EngineErrorCode;
import app.qesma.engine.EngineException;
import app.qesma.engine.ItemizedCalculator;
import app.qesma.engine.Limits;
import app.qesma.engine.MemberRef;
import app.qesma.engine.Payer;
import app.qesma.engine.PayerValidator;
import app.qesma.engine.Share;
import app.qesma.engine.SplitCalculator;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;

/**
 * The single mapping + validation pipeline from a validated request to engine results. Create and preview both
 * go through {@link #compute}, so they cannot disagree on a number or a rule. No I/O, no persistence: every money
 * rule is delegated to the pure engine; this class only maps ids and engine errors.
 */
final class ExpenseCalculator {

    /**
     * Everything the engine decided about a request. Itemized fields are null for EQUAL/EXACT; for ITEMIZED
     * {@code serviceBps}/{@code taxBps} are null when that charge is off (its amount is then 0).
     */
    record Computation(String splitType, long totalMinor, Long subtotalMinor, Integer serviceBps, long serviceMinor,
                       Integer taxBps, String taxBase, long taxMinor, long adjustmentMinor,
                       List<ExpenseView.ShareView> shares, List<Payer> payers) {

        boolean itemized() {
            return splitType.equals(Expense.ITEMIZED);
        }
    }

    private ExpenseCalculator() {
    }

    /** Resolves the roster, runs the engine for the split type and returns the shares in member sort order. */
    static Computation compute(ExpenseValidator.Valid request, List<Member> members) {
        Map<String, MemberRef> roster = new LinkedHashMap<>();
        for (Member m : members) {
            roster.put(m.getId().toString(), new MemberRef(m.getId().toString(), m.getSortOrder()));
        }
        List<Payer> payers = new ArrayList<>();
        for (ExpenseCommand.PayerInput p : request.payers()) {
            payers.add(new Payer(requireMember(roster, p.memberId()), p.amountMinor()));
        }
        try {
            Computation computed = switch (request.splitType()) {
                case Expense.EQUAL -> equal(request, roster, payers);
                case Expense.EXACT -> exact(request, roster, payers);
                default -> itemized(request, roster, payers);
            };
            // The engine computes an ITEMIZED total itself: it must respect the same cap as a stated one (CP2-001).
            if (!Limits.withinAmountLimit(computed.totalMinor())) {
                throw ApiException.validation("The bill total must be at most " + Limits.MAX_AMOUNT_MINOR);
            }
            return computed;
        } catch (EngineException e) {
            throw EngineErrors.toApi(e);
        }
    }

    /** Create: the payers must add up to the total, otherwise PAYERS_TOTAL_MISMATCH (or another 422). */
    static void requirePayersMatch(Computation c) {
        try {
            PayerValidator.validate(c.totalMinor(), c.payers());
        } catch (EngineException e) {
            throw EngineErrors.toApi(e);
        }
    }

    /** Preview: a mismatch (or no payers yet) is information for the UI, not an error. Other violations still fail. */
    static boolean payersMatch(Computation c) {
        if (c.payers().isEmpty()) {
            return false;
        }
        try {
            PayerValidator.validate(c.totalMinor(), c.payers());
            return true;
        } catch (EngineException e) {
            if (e.code() == EngineErrorCode.PAYERS_TOTAL_MISMATCH) {
                return false;
            }
            throw EngineErrors.toApi(e);
        }
    }

    private static Computation equal(ExpenseValidator.Valid request, Map<String, MemberRef> roster,
                                     List<Payer> payers) {
        List<MemberRef> participants = new ArrayList<>();
        if (request.participantMemberIds() == null) {
            participants.addAll(roster.values());                                // "All": explicit snapshot
        } else {
            for (UUID id : request.participantMemberIds()) {
                participants.add(roster.get(requireMember(roster, id)));
            }
        }
        Map<String, Long> owed = SplitCalculator.equal(request.totalMinor(), participants);
        return plain(request, roster, owed, payers);
    }

    private static Computation exact(ExpenseValidator.Valid request, Map<String, MemberRef> roster,
                                     List<Payer> payers) {
        List<Share> shares = new ArrayList<>();
        for (ExpenseCommand.ShareInput s : request.shares()) {
            shares.add(new Share(requireMember(roster, s.memberId()), s.amountMinor()));
        }
        return plain(request, roster, SplitCalculator.exact(request.totalMinor(), shares), payers);
    }

    private static Computation plain(ExpenseValidator.Valid request, Map<String, MemberRef> roster,
                                     Map<String, Long> owed, List<Payer> payers) {
        List<ExpenseView.ShareView> shares = owed.entrySet().stream()
                .sorted(Comparator.comparingInt(e -> roster.get(e.getKey()).sortOrder()))
                .map(e -> new ExpenseView.ShareView(UUID.fromString(e.getKey()), e.getValue()))
                .toList();
        return new Computation(request.splitType(), request.totalMinor(), null, null, 0, null, null, 0, 0, shares,
                payers);
    }

    private static Computation itemized(ExpenseValidator.Valid request, Map<String, MemberRef> roster,
                                        List<Payer> payers) {
        List<ItemizedCalculator.Item> items = new ArrayList<>();
        for (ExpenseCommand.ItemInput item : request.items()) {
            List<String> assignees = new ArrayList<>();
            for (UUID id : item.assigneeMemberIds()) {
                assignees.add(requireMember(roster, id));
            }
            items.add(new ItemizedCalculator.Item(item.name(), item.amountMinor(), assignees));
        }
        ItemizedCalculator.TaxSpec tax = request.taxBps() == null ? null
                : new ItemizedCalculator.TaxSpec(request.taxBps(), ItemizedCalculator.TaxBase.valueOf(request.taxBase()));
        ItemizedCalculator.ItemizedResult r = ItemizedCalculator.calculate(new ItemizedCalculator.ItemizedInput(
                new ArrayList<>(roster.values()), items, request.serviceBps(), tax, request.adjustmentMinor()));

        if (request.totalMinor() != 0 && request.totalMinor() != r.totalMinor()) {
            throw new ApiException(ErrorCode.SPLIT_TOTAL_MISMATCH, HttpStatus.UNPROCESSABLE_ENTITY,
                    "totalMinor does not match the computed bill total");
        }
        List<ExpenseView.ShareView> shares = r.members().stream()
                .map(m -> new ExpenseView.ShareView(UUID.fromString(m.memberId()), m.owedMinor(), m.itemsMinor(),
                        m.serviceMinor(), m.taxMinor(), m.adjustmentMinor()))
                .toList();
        return new Computation(Expense.ITEMIZED, r.totalMinor(), r.subtotalMinor(), request.serviceBps(),
                r.serviceMinor(), request.taxBps(), request.taxBase(), r.taxMinor(), r.adjustmentMinor(), shares,
                payers);
    }

    /** Spec 6 notes: every referenced member must belong to the expense's group. */
    private static String requireMember(Map<String, MemberRef> roster, UUID memberId) {
        String id = memberId.toString();
        if (!roster.containsKey(id)) {
            throw new ApiException(ErrorCode.MEMBER_NOT_IN_GROUP, HttpStatus.UNPROCESSABLE_ENTITY,
                    "A referenced member is not part of this group");
        }
        return id;
    }
}
