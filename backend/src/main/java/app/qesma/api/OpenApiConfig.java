package app.qesma.api;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.PathItem;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.media.Content;
import io.swagger.v3.oas.models.media.IntegerSchema;
import io.swagger.v3.oas.models.media.MediaType;
import io.swagger.v3.oas.models.media.ObjectSchema;
import io.swagger.v3.oas.models.media.Schema;
import io.swagger.v3.oas.models.media.StringSchema;
import io.swagger.v3.oas.models.parameters.Parameter;
import io.swagger.v3.oas.models.responses.ApiResponse;
import io.swagger.v3.oas.models.responses.ApiResponses;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import org.springdoc.core.customizers.OpenApiCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Completes the generated OpenAPI document so a client generator gets the whole contract (B8): bearer security, the
 * RFC 7807 {@code Problem} schema with every error code, which errors each operation can return, required
 * {@code Idempotency-Key}/{@code If-Match} headers, and the unit of every money and percentage field.
 * The bean always exists; springdoc only serves the document where it is enabled (local, tests, export).
 */
@Configuration
public class OpenApiConfig {

    static final String PROBLEM = "Problem";
    static final String BEARER = "bearerAuth";
    static final String MONEY_NOTE = "Integer minor units (piasters: 1 EGP = 100). Never a decimal.";
    static final String BPS_NOTE = "Integer basis points: 1200 = 12.00%.";

    @Bean
    OpenApiCustomizer qesmaOpenApiCustomizer() {
        return openApi -> {
            openApi.setInfo(new Info().title("Qesma API").version("1.0.0").description("""
                    Backend of Qesma, a group expense-splitting app. It only records who paid what and who owes
                    whom; it never moves money. All amounts are integer minor units (piasters). The backend is
                    authoritative for every calculation. Errors are RFC 7807 problem+json with a stable `code`.
                    Create operations need an `Idempotency-Key` (UUID); edits and deletes need `If-Match` with the
                    entity version (the `ETag` of the last read)."""));
            openApi.setServers(List.of(new Server().url("/").description("Same origin as this document")));
            Components components = openApi.getComponents() == null ? new Components() : openApi.getComponents();
            openApi.setComponents(components);
            components.addSecuritySchemes(BEARER,
                    new SecurityScheme().type(SecurityScheme.Type.HTTP).scheme("bearer").bearerFormat("JWT")
                            .description("Access token from POST /api/v1/auth/google or /auth/refresh (15 minutes)."));
            components.addSchemas(PROBLEM, problemSchema());
            openApi.addSecurityItem(new SecurityRequirement().addList(BEARER));
            describeUnits(components);
            typeRevisionSnapshot(components);
            markRequiredAndNullable(components);

            Map<String, PathItem> paths = openApi.getPaths();
            if (paths != null) {
                paths.forEach((path, item) -> item.readOperationsMap().forEach((method, op) -> {
                    if (isPublicAuth(path)) {
                        op.setSecurity(List.of());            // sign-in, refresh and logout carry no access token
                    }
                    op.setOperationId(operationId(path, method));
                    markRequiredHeaders(op);
                    jsonOnly(op);
                    addErrors(path, method, op);
                }));
            }
        };
    }

    // ---- operation ids (the method names of the generated Dart client) ---------------------------------------------

    /** Meaningful, stable names instead of springdoc's {@code delete_1}/{@code get_2}. A new endpoint must be added here. */
    public static final Map<String, String> OPERATION_IDS = Map.ofEntries(
            Map.entry("POST /api/v1/auth/google", "signInWithGoogle"),
            Map.entry("POST /api/v1/auth/refresh", "refreshSession"),
            Map.entry("POST /api/v1/auth/logout", "signOut"),
            Map.entry("POST /api/v1/auth/register", "registerWithPassword"),
            Map.entry("POST /api/v1/auth/login", "signInWithPassword"),
            Map.entry("POST /api/v1/auth/password/forgot", "forgotPassword"),
            Map.entry("POST /api/v1/auth/password/reset", "resetPassword"),
            Map.entry("POST /api/v1/auth/email/verify", "verifyEmail"),
            Map.entry("POST /api/v1/auth/email/verify/resend", "resendEmailVerification"),
            Map.entry("POST /api/v1/me/password", "changePassword"),
            Map.entry("GET /api/v1/me", "getMe"),
            Map.entry("PATCH /api/v1/me", "updateMe"),
            Map.entry("GET /api/v1/me/payment-handles", "getPaymentHandles"),
            Map.entry("PUT /api/v1/me/payment-handles", "updatePaymentHandles"),
            Map.entry("GET /api/v1/groups", "listGroups"),
            Map.entry("POST /api/v1/groups", "createGroup"),
            Map.entry("GET /api/v1/groups/{gid}", "getGroup"),
            Map.entry("PATCH /api/v1/groups/{gid}", "updateGroup"),
            Map.entry("DELETE /api/v1/groups/{gid}", "deleteGroup"),
            Map.entry("POST /api/v1/groups/{gid}/members", "addMember"),
            Map.entry("PATCH /api/v1/groups/{gid}/members/{mid}", "renameMember"),
            Map.entry("DELETE /api/v1/groups/{gid}/members/{mid}", "deleteMember"),
            Map.entry("GET /api/v1/groups/{gid}/expenses", "listExpenses"),
            Map.entry("POST /api/v1/groups/{gid}/expenses", "createExpense"),
            Map.entry("POST /api/v1/groups/{gid}/expenses/preview", "previewExpense"),
            Map.entry("GET /api/v1/groups/{gid}/expenses/{eid}", "getExpense"),
            Map.entry("PUT /api/v1/groups/{gid}/expenses/{eid}", "updateExpense"),
            Map.entry("DELETE /api/v1/groups/{gid}/expenses/{eid}", "deleteExpense"),
            Map.entry("GET /api/v1/groups/{gid}/expenses/{eid}/revisions", "listExpenseRevisions"),
            Map.entry("GET /api/v1/groups/{gid}/balances", "getBalances"),
            Map.entry("GET /api/v1/groups/{gid}/settlements", "listSettlements"),
            Map.entry("POST /api/v1/groups/{gid}/settlements", "createSettlement"),
            Map.entry("POST /api/v1/groups/{gid}/settlements/{sid}/confirm", "confirmSettlement"),
            Map.entry("POST /api/v1/groups/{gid}/settlements/{sid}/dispute", "disputeSettlement"),
            Map.entry("POST /api/v1/groups/{gid}/settlements/{sid}/cancel", "cancelSettlement"),
            Map.entry("POST /api/v1/groups/{gid}/invites", "createInvite"),
            Map.entry("GET /api/v1/groups/{gid}/invites", "listInvites"),
            Map.entry("DELETE /api/v1/groups/{gid}/invites/{iid}", "revokeInvite"),
            Map.entry("GET /api/v1/invites/{code}", "getInvitePreview"),
            Map.entry("POST /api/v1/invites/{code}/join", "joinGroup"),
            Map.entry("GET /api/v1/groups/{gid}/join-requests", "listJoinRequests"),
            Map.entry("POST /api/v1/groups/{gid}/join-requests/{rid}/approve", "approveJoinRequest"),
            Map.entry("POST /api/v1/groups/{gid}/join-requests/{rid}/reject", "rejectJoinRequest"),
            Map.entry("POST /api/v1/groups/{gid}/members/{mid}/unlink", "unlinkMember"),
            Map.entry("POST /api/v1/groups/{gid}/leave", "leaveGroup"),
            Map.entry("POST /api/v1/groups/{gid}/transfer-ownership", "transferOwnership"),
            Map.entry("GET /api/v1/groups/{gid}/activity", "listGroupActivity"),
            Map.entry("GET /api/v1/notifications", "listNotifications"),
            Map.entry("GET /api/v1/notifications/unread-count", "getUnreadNotificationCount"),
            Map.entry("POST /api/v1/notifications/read", "markNotificationsRead"),
            // B16: preferences and Remind
            Map.entry("PUT /api/v1/me/notification-prefs", "updateNotificationPrefs"),
            Map.entry("PUT /api/v1/groups/{gid}/notification-prefs", "updateGroupNotificationPrefs"),
            Map.entry("POST /api/v1/groups/{gid}/transfers/remind", "remindTransfer"));

    static String operationId(String path, PathItem.HttpMethod method) {
        String id = OPERATION_IDS.get(method + " " + path);
        if (id == null) {
            throw new IllegalStateException("No operationId for " + method + " " + path + ": add it to OpenApiConfig.OPERATION_IDS");
        }
        return id;
    }

    // ---- error responses ---------------------------------------------------------------------------------------

    /** The error codes an operation can return, grouped by HTTP status. Derived from the operation's shape. */
    /** Group-scoped operations every active member may call; all others need a role (403 FORBIDDEN otherwise). */
    private static final java.util.Set<String> OPEN_TO_EVERY_MEMBER = java.util.Set.of(
            "GET /api/v1/groups/{gid}", "GET /api/v1/groups/{gid}/expenses", "POST /api/v1/groups/{gid}/expenses",
            "POST /api/v1/groups/{gid}/expenses/preview", "GET /api/v1/groups/{gid}/expenses/{eid}",
            "GET /api/v1/groups/{gid}/expenses/{eid}/revisions", "GET /api/v1/groups/{gid}/balances",
            "GET /api/v1/groups/{gid}/settlements", "GET /api/v1/groups/{gid}/activity",
            "POST /api/v1/groups/{gid}/leave", "PUT /api/v1/groups/{gid}/notification-prefs");

    static Map<Integer, List<ErrorCode>> errorsFor(String path, PathItem.HttpMethod method, Operation op) {
        Map<Integer, List<ErrorCode>> errors = new TreeMap<>();
        boolean auth = isPublicAuth(path);
        boolean hasBody = op.getRequestBody() != null;
        boolean ifMatch = hasHeader(op, "If-Match");
        boolean idempotent = hasHeader(op, "Idempotency-Key");
        boolean expenseWrite = path.endsWith("/expenses") && method == PathItem.HttpMethod.POST
                || path.endsWith("/expenses/preview") || path.endsWith("/expenses/{eid}") && method == PathItem.HttpMethod.PUT;

        if (!auth) {
            add(errors, 401, ErrorCode.UNAUTHORIZED);
        }
        if (hasBody || hasQueryParam(op)) {
            add(errors, 400, ErrorCode.VALIDATION_ERROR);      // malformed JSON or a malformed query/path value
        }
        if (path.contains("{gid}")) {
            add(errors, 404, ErrorCode.NOT_FOUND);
            // Roles (Phase 2, A65/A67): reads, expense/settlement creation and the preview are open to every member;
            // everything else depends on the role (and, for expenses/settlements, on who created it).
            if (!OPEN_TO_EVERY_MEMBER.contains(method + " " + path)) {
                add(errors, 403, ErrorCode.FORBIDDEN);
            }
        }
        if (path.startsWith("/api/v1/invites/")) {
            // the code is the capability: no group authorization, but guessing is limited (B11)
            add(errors, 404, ErrorCode.NOT_FOUND);
            add(errors, 410, ErrorCode.INVITE_EXPIRED);
            add(errors, 410, ErrorCode.INVITE_REVOKED);
            add(errors, 429, ErrorCode.RATE_LIMITED);
        }
        add(errors, 422, ErrorCode.VALIDATION_ERROR);          // bad input, also malformed JSON/parameters (400 is mapped to 422 too)
        if (hasBody) {
            add(errors, 413, ErrorCode.VALIDATION_ERROR);
        }
        if (ifMatch) {
            add(errors, 409, ErrorCode.VERSION_CONFLICT);
            add(errors, 428, ErrorCode.VALIDATION_ERROR);
        }
        if (idempotent) {
            add(errors, 422, ErrorCode.IDEMPOTENCY_KEY_REUSED);
        }
        if (expenseWrite) {
            add(errors, 422, ErrorCode.PAYERS_TOTAL_MISMATCH);
            add(errors, 422, ErrorCode.SPLIT_TOTAL_MISMATCH);
            add(errors, 422, ErrorCode.MEMBER_NOT_IN_GROUP);
        }
        if (path.endsWith("/settlements") && method == PathItem.HttpMethod.POST) {
            add(errors, 422, ErrorCode.MEMBER_NOT_IN_GROUP);
        }
        if (path.endsWith("/members") && method == PathItem.HttpMethod.POST
                || path.endsWith("/members/{mid}") && method == PathItem.HttpMethod.PATCH) {
            add(errors, 409, ErrorCode.DUPLICATE_MEMBER_NAME);
        }
        if (path.endsWith("/members/{mid}") && method == PathItem.HttpMethod.DELETE) {
            add(errors, 409, ErrorCode.MEMBER_HAS_TRANSACTIONS);
            add(errors, 409, ErrorCode.OWNER_MEMBER_PROTECTED);
        }
        if (path.endsWith("/groups/{gid}") && method == PathItem.HttpMethod.DELETE) {
            add(errors, 409, ErrorCode.GROUP_NOT_EMPTY);
        }
        if (path.endsWith("/members/{mid}/unlink")
                || path.endsWith("/members/{mid}") && method == PathItem.HttpMethod.PATCH) {
            add(errors, 409, ErrorCode.OWNER_MEMBER_PROTECTED);
        }
        if (path.endsWith("/settlements/{sid}/confirm") || path.endsWith("/settlements/{sid}/dispute")
                || path.endsWith("/settlements/{sid}/cancel")) {
            add(errors, 409, ErrorCode.INVALID_STATE_TRANSITION);          // B13: the state machine refused it
        }
        if (path.endsWith("/transfers/remind")) {                              // B16
            add(errors, 422, ErrorCode.MEMBER_NOT_IN_GROUP);
            add(errors, 422, ErrorCode.MEMBER_INACTIVE);
            add(errors, 429, ErrorCode.REMIND_RATE_LIMITED);
        }
        if (path.endsWith("/leave")) {
            add(errors, 409, ErrorCode.OWNER_MUST_TRANSFER);
        }
        if (path.endsWith("/transfer-ownership")) {
            add(errors, 422, ErrorCode.MEMBER_INACTIVE);
        }
        if (expenseWrite || path.endsWith("/settlements") && method == PathItem.HttpMethod.POST) {
            add(errors, 422, ErrorCode.MEMBER_INACTIVE);                   // B12: a member who left is not usable
        }
        if (path.endsWith("/join") || path.endsWith("/approve")) {          // B11: the three ways joining can collide
            add(errors, 409, ErrorCode.ALREADY_MEMBER);
            add(errors, 409, ErrorCode.MEMBER_ALREADY_CLAIMED);
            add(errors, 409, ErrorCode.DUPLICATE_MEMBER_NAME);
            add(errors, 422, ErrorCode.MEMBER_NOT_IN_GROUP);
        }
        if (path.endsWith("/approve")) {
            add(errors, 410, ErrorCode.INVITE_EXPIRED);
        }
        if (path.endsWith("/approve") || path.endsWith("/reject")) {
            add(errors, 409, ErrorCode.VERSION_CONFLICT);                  // already decided the other way
        }
        if (auth) {
            add(errors, 401, ErrorCode.UNAUTHORIZED);
            add(errors, 429, ErrorCode.RATE_LIMITED);
        }
        if (path.equals("/api/v1/auth/register")) {
            add(errors, 409, ErrorCode.USERNAME_TAKEN);
        }
        if (path.equals("/api/v1/auth/google")) {
            add(errors, 503, ErrorCode.AUTH_PROVIDER_UNAVAILABLE);
        }
        add(errors, 500, ErrorCode.INTERNAL_ERROR);
        return errors;
    }

    /** Auth endpoints that carry no access token. Resending the verification link needs one, like the rest of the API. */
    private static boolean isPublicAuth(String path) {
        return path.startsWith("/api/v1/auth/") && !path.equals("/api/v1/auth/email/verify/resend");
    }

    private static void add(Map<Integer, List<ErrorCode>> errors, int status, ErrorCode code) {
        List<ErrorCode> codes = errors.computeIfAbsent(status, s -> new ArrayList<>());
        if (!codes.contains(code)) {
            codes.add(code);
        }
    }

    private void addErrors(String path, PathItem.HttpMethod method, Operation op) {
        ApiResponses responses = op.getResponses() == null ? new ApiResponses() : op.getResponses();
        op.setResponses(responses);
        errorsFor(path, method, op).forEach((status, codes) -> {
            String key = Integer.toString(status);
            String codeList = codes.stream().map(ErrorCode::name).reduce((a, b) -> a + ", " + b).orElse("");
            ApiResponse response = new ApiResponse().description(describe(status) + " (code: " + codeList + ")")
                    .content(new Content().addMediaType("application/problem+json",
                            new MediaType().schema(new Schema<>().$ref("#/components/schemas/" + PROBLEM))));
            ApiResponse existing = responses.get(key);
            if (existing == null) {
                responses.addApiResponse(key, response);
            } else {
                existing.setDescription((existing.getDescription() == null ? "" : existing.getDescription() + "; ")
                        + describe(status) + " (code: " + codeList + ")");
            }
        });
    }

    private static String describe(int status) {
        return switch (status) {
            case 400 -> "Malformed request";
            case 401 -> "Not authenticated";
            case 403 -> "You are a member of the group but your role does not allow this";
            case 404 -> "Not found, or you are not a member of the group (identical answer)";
            case 409 -> "Conflict";
            case 410 -> "Gone: the invitation expired, was used up or was revoked";
            case 413 -> "Request body too large";
            case 422 -> "Rejected";
            case 428 -> "If-Match header required";
            case 429 -> "Too many requests";
            case 503 -> "Sign-in provider unavailable";
            default -> "Unexpected error";
        };
    }

    // ---- schema details -------------------------------------------------------------------------------------------

    private static Schema<?> problemSchema() {
        StringSchema code = new StringSchema();
        code.description("Stable machine-readable error code.");
        code.setEnum(Arrays.stream(ErrorCode.values()).map(Enum::name).toList());
        Schema<?> problem = new ObjectSchema().description("RFC 7807 problem details (application/problem+json).");
        problem.addProperty("type", new StringSchema().format("uri"));
        problem.addProperty("title", new StringSchema());
        problem.addProperty("status", new IntegerSchema().format("int32"));
        problem.addProperty("detail", new StringSchema().nullable(true));
        problem.addProperty("instance", new StringSchema().format("uri"));
        problem.addProperty("code", code);
        problem.addProperty("requestId", new StringSchema().description("Echoes the X-Request-Id response header."));
        problem.addProperty("nextAllowedAt", new StringSchema().format("date-time").description(
                "Only with REMIND_RATE_LIMITED: the earliest time a reminder for this member may be sent again (UTC)."));
        problem.setRequired(List.of("type", "title", "status", "code"));
        return problem;
    }

    /** Money and percentage fields carry their unit in the schema so a generated client cannot misread them. */
    @SuppressWarnings({"rawtypes", "unchecked"})
    private static void describeUnits(Components components) {
        if (components.getSchemas() == null) {
            return;
        }
        for (Schema<?> schema : new LinkedHashMap<>(components.getSchemas()).values()) {
            Map<String, Schema> props = schema.getProperties();
            if (props == null) {
                continue;
            }
            props.forEach((name, prop) -> {
                if (name.endsWith("Minor")) {
                    prop.setDescription(MONEY_NOTE);
                } else if (name.equals("bps")) {
                    prop.setDescription(BPS_NOTE);
                }
            });
        }
    }

    /** Response objects always carry every field (null where noted), so a generated client gets non-null types. */
    private static final java.util.Set<String> RESPONSE_SCHEMAS = java.util.Set.of("AuthResponse", "TokenResponse",
            "UserDto", "GroupDto", "GroupSummaryDto", "MemberDto", "ExpenseView", "ExpensePreview", "BalanceView", "Net",
            "TransferView", "SettlementView", "ExpenseRevisionView", "Charges", "ServiceCharge", "TaxCharge", "ItemView",
            "PayerView", "ShareView", "PaymentHandlesView", "ActivityPage", "ActivityItem", "NotificationPage",
            "NotificationItem", "UnreadCount", "MarkReadResult", "EventPayload", "ReminderView", "NotificationPrefsView",
            "GroupNotificationPrefsView");

    /** Response fields that can be null (all other response fields are always present and non-null). */
    static final Map<String, java.util.Set<String>> NULLABLE = Map.ofEntries(
            Map.entry("ExpenseView", java.util.Set.of("items", "charges")),
            Map.entry("ShareView", java.util.Set.of("itemsMinor", "serviceMinor", "taxMinor", "adjustmentMinor")),
            Map.entry("Charges", java.util.Set.of("service", "tax")),
            Map.entry("ExpensePreview", java.util.Set.of("subtotalMinor", "serviceMinor", "taxMinor", "adjustmentMinor")),
            Map.entry("SettlementView", java.util.Set.of("note", "createdByMemberId", "confirmedAt", "disputedAt", "cancelledAt")),
            Map.entry("GroupDto", java.util.Set.of("lastExpenseAt")),
            Map.entry("GroupSummaryDto", java.util.Set.of("lastExpenseAt")),
            Map.entry("UserDto", java.util.Set.of("email", "username")),
            Map.entry("TransferView", java.util.Set.of("receiverHandles", "canRemindAt")),
            Map.entry("PaymentHandlesView", java.util.Set.of("instapay", "wallet")),
            // B15: the feed shapes. Which payload fields are set depends on the event type, so none is required.
            Map.entry("ActivityPage", java.util.Set.of("nextBefore")),
            Map.entry("NotificationPage", java.util.Set.of("nextBefore")),
            Map.entry("ActivityItem", java.util.Set.of("actorMemberId", "subject")),
            Map.entry("NotificationItem", java.util.Set.of("actorMemberId", "actorName", "readAt", "subject")),
            Map.entry("EventPayload", java.util.Set.of("expenseId", "settlementId", "memberId", "requestId", "inviteId",
                    "fromMemberId", "toMemberId", "version", "totalMinor", "amountMinor", "role", "previousRole")));

    /** Request fields a caller must send. Other request fields are optional (the server defaults or ignores them). */
    static final Map<String, List<String>> REQUIRED_REQUEST = Map.ofEntries(
            Map.entry("CreateGroupRequest", List.of("name", "type")),
            Map.entry("CreateMemberRequest", List.of("displayName")),
            Map.entry("UpdateMeRequest", List.of("displayName")),
            Map.entry("RegisterRequest", List.of("username", "password")),
            Map.entry("LoginRequest", List.of("username", "password")),
            Map.entry("ForgotPasswordRequest", List.of("email")),
            Map.entry("ResetPasswordRequest", List.of("token", "newPassword")),
            Map.entry("VerifyEmailRequest", List.of("token")),
            Map.entry("ChangePasswordRequest", List.of("currentPassword", "newPassword")),
            Map.entry("RemindCommand", List.of("fromMemberId", "toMemberId")),
            Map.entry("UpdateNotificationPrefsRequest", List.of("enabled")),
            Map.entry("UpdateGroupNotificationPrefsRequest", List.of("muted")),
            Map.entry("SettlementCommand", List.of("fromMemberId", "toMemberId", "amountMinor", "settledOn")),
            Map.entry("ExpenseCommand", List.of("title", "expenseDate", "splitType")),
            Map.entry("PayerInput", List.of("memberId", "amountMinor")),
            Map.entry("ShareInput", List.of("memberId", "amountMinor")),
            Map.entry("ItemInput", List.of("name", "amountMinor", "assigneeMemberIds")),
            Map.entry("ServiceInput", List.of("bps")),
            Map.entry("TaxInput", List.of("bps")));

    @SuppressWarnings({"rawtypes", "unchecked"})
    private static void markRequiredAndNullable(Components components) {
        if (components.getSchemas() == null) {
            return;
        }
        components.getSchemas().forEach((name, schema) -> {
            Map<String, Schema> props = schema.getProperties();
            if (props == null) {
                return;
            }
            if (RESPONSE_SCHEMAS.contains(name) || name.startsWith("PageResponse")) {
                java.util.Set<String> nullable = NULLABLE.getOrDefault(name, java.util.Set.of());
                List<String> required = new ArrayList<>();
                for (Map.Entry<String, Schema> p : props.entrySet()) {
                    if (nullable.contains(p.getKey())) {
                        if (p.getValue().get$ref() == null) {
                            p.getValue().setNullable(true);
                        }
                    } else {
                        required.add(p.getKey());
                    }
                }
                required.sort(String::compareTo);
                schema.setRequired(required);
            } else if (REQUIRED_REQUEST.containsKey(name)) {
                schema.setRequired(new ArrayList<>(REQUIRED_REQUEST.get(name)));
            }
        });
    }

    private static boolean hasQueryParam(Operation op) {
        return op.getParameters() != null && op.getParameters().stream().anyMatch(p -> "query".equals(p.getIn()));
    }

    /** springdoc documents un-annotated responses with a wildcard media type; this API only speaks JSON. */
    private static void jsonOnly(Operation op) {
        if (op.getResponses() == null) {
            return;
        }
        for (ApiResponse response : op.getResponses().values()) {
            Content content = response.getContent();
            if (content != null && content.containsKey("*/*")) {
                MediaType any = content.remove("*/*");
                content.addMediaType("application/json", any);
            }
        }
    }

    /** The revision snapshot is the expense as the API returns it: say so instead of an opaque JsonNode. */
    private static void typeRevisionSnapshot(Components components) {
        if (components.getSchemas() == null || !components.getSchemas().containsKey("ExpenseRevisionView")) {
            return;
        }
        components.getSchemas().get("ExpenseRevisionView").addProperty("snapshot",
                new Schema<>().$ref("#/components/schemas/ExpenseView")
                        .description("The complete expense as it was right after this change."));
        components.getSchemas().remove("JsonNode");
    }

    private static boolean hasHeader(Operation op, String name) {
        return op.getParameters() != null && op.getParameters().stream()
                .anyMatch(p -> "header".equals(p.getIn()) && name.equalsIgnoreCase(p.getName()));
    }

    /** The controllers read these headers as optional so they can answer 422/428 themselves; the contract says required. */
    private static void markRequiredHeaders(Operation op) {
        if (op.getParameters() == null) {
            return;
        }
        for (Parameter p : op.getParameters()) {
            if (!"header".equals(p.getIn())) {
                continue;
            }
            if ("Idempotency-Key".equalsIgnoreCase(p.getName())) {
                p.setRequired(true);
                p.setDescription("Client-generated UUID, one per create action. Reuse the same key when retrying the "
                        + "SAME action: the stored answer is returned (header Idempotency-Replayed: true). Keys are "
                        + "kept 24 hours.");
                p.setSchema(new StringSchema().format("uuid"));
            } else if ("If-Match".equalsIgnoreCase(p.getName())) {
                p.setRequired(true);
                p.setDescription("The entity version from the last read, as returned in ETag, e.g. \"3\".");
                p.setSchema(new StringSchema().example("\"1\""));
            }
        }
    }
}
