package app.qesma.api;

/** Request examples shown in the OpenAPI document for the create and preview expense endpoints (spec 8.4). */
final class ApiExamples {

    static final String EQUAL = """
            {"title":"Dinner","expenseDate":"2026-10-18","splitType":"EQUAL","totalMinor":10000,
             "payers":[{"memberId":"11111111-1111-1111-1111-111111111111","amountMinor":10000}]}""";

    static final String EXACT = """
            {"title":"Taxi","expenseDate":"2026-10-18","splitType":"EXACT","totalMinor":10000,
             "payers":[{"memberId":"11111111-1111-1111-1111-111111111111","amountMinor":10000}],
             "shares":[{"memberId":"22222222-2222-2222-2222-222222222222","amountMinor":4000},
                       {"memberId":"33333333-3333-3333-3333-333333333333","amountMinor":6000}]}""";

    static final String ITEMIZED = """
            {"title":"Seafood dinner","expenseDate":"2026-10-18","splitType":"ITEMIZED",
             "payers":[{"memberId":"11111111-1111-1111-1111-111111111111","amountMinor":44688}],
             "items":[{"name":"Pizza","amountMinor":20000,
                       "assigneeMemberIds":["11111111-1111-1111-1111-111111111111","22222222-2222-2222-2222-222222222222"]},
                      {"name":"Pasta","amountMinor":15000,
                       "assigneeMemberIds":["33333333-3333-3333-3333-333333333333"]}],
             "service":{"bps":1200},
             "tax":{"bps":1400,"base":"SUBTOTAL_PLUS_SERVICE"},
             "adjustmentMinor":0}""";

    /** BSA3 (A185-A186): rent for November by units 2 / 1 / 1, the third member present from the 12th (V23). */
    static final String SHARES = """
            {"title":"Rent","expenseDate":"2026-12-01","splitType":"SHARES","totalMinor":900000,
             "payers":[{"memberId":"11111111-1111-1111-1111-111111111111","amountMinor":900000}],
             "periodFrom":"2026-11-01","periodTo":"2026-11-30",
             "shareParticipants":[{"memberId":"11111111-1111-1111-1111-111111111111","shareUnits":2},
                                  {"memberId":"22222222-2222-2222-2222-222222222222","shareUnits":1},
                                  {"memberId":"33333333-3333-3333-3333-333333333333","shareUnits":1,
                                   "presentFrom":"2026-11-12"}]}""";

    private ApiExamples() {
    }
}
