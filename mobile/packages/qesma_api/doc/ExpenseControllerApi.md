# qesma_api.api.ExpenseControllerApi

## Load the API package
```dart
import 'package:qesma_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createExpense**](ExpenseControllerApi.md#createexpense) | **POST** /api/v1/groups/{gid}/expenses | Create an expense (EQUAL, EXACT or ITEMIZED)
[**deleteExpense**](ExpenseControllerApi.md#deleteexpense) | **DELETE** /api/v1/groups/{gid}/expenses/{eid} | Delete an expense (soft delete, keeps the history)
[**getExpense**](ExpenseControllerApi.md#getexpense) | **GET** /api/v1/groups/{gid}/expenses/{eid} | 
[**listExpenseRevisions**](ExpenseControllerApi.md#listexpenserevisions) | **GET** /api/v1/groups/{gid}/expenses/{eid}/revisions | History of an expense, oldest first
[**listExpenses**](ExpenseControllerApi.md#listexpenses) | **GET** /api/v1/groups/{gid}/expenses | 
[**previewExpense**](ExpenseControllerApi.md#previewexpense) | **POST** /api/v1/groups/{gid}/expenses/preview | Preview an expense split without saving it
[**updateExpense**](ExpenseControllerApi.md#updateexpense) | **PUT** /api/v1/groups/{gid}/expenses/{eid} | Edit an expense (replaces payers, shares and items)


# **createExpense**
> ExpenseView createExpense(gid, idempotencyKey, expenseCommand)

Create an expense (EQUAL, EXACT or ITEMIZED)

Idempotency-Key (UUID) is required. For ITEMIZED, totalMinor is optional: the server computes it and the payers must add up to it (PAYERS_TOTAL_MISMATCH otherwise).

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getExpenseControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Client-generated UUID, one per create action. Reuse the same key when retrying the SAME action: the stored answer is returned (header Idempotency-Replayed: true). Keys are kept 24 hours.
final ExpenseCommand expenseCommand = {"expenseDate":"2026-10-18","payers":[{"amountMinor":10000,"memberId":"11111111-1111-1111-1111-111111111111"}],"splitType":"EQUAL","title":"Dinner","totalMinor":10000}; // ExpenseCommand | 

try {
    final response = api.createExpense(gid, idempotencyKey, expenseCommand);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ExpenseControllerApi->createExpense: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **idempotencyKey** | **String**| Client-generated UUID, one per create action. Reuse the same key when retrying the SAME action: the stored answer is returned (header Idempotency-Replayed: true). Keys are kept 24 hours. | 
 **expenseCommand** | [**ExpenseCommand**](ExpenseCommand.md)|  | 

### Return type

[**ExpenseView**](ExpenseView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteExpense**
> deleteExpense(gid, eid, ifMatch)

Delete an expense (soft delete, keeps the history)

If-Match with the current version is required. Answers 204 with the new ETag.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getExpenseControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String eid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String ifMatch = "1"; // String | The entity version from the last read, as returned in ETag, e.g. \"3\".

try {
    api.deleteExpense(gid, eid, ifMatch);
} catch on DioException (e) {
    print('Exception when calling ExpenseControllerApi->deleteExpense: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **eid** | **String**|  | 
 **ifMatch** | **String**| The entity version from the last read, as returned in ETag, e.g. \"3\". | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getExpense**
> ExpenseView getExpense(gid, eid)



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getExpenseControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String eid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getExpense(gid, eid);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ExpenseControllerApi->getExpense: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **eid** | **String**|  | 

### Return type

[**ExpenseView**](ExpenseView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listExpenseRevisions**
> BuiltList<ExpenseRevisionView> listExpenseRevisions(gid, eid)

History of an expense, oldest first

Each entry carries the full expense as it was after that change. Still available after the expense was deleted.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getExpenseControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String eid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.listExpenseRevisions(gid, eid);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ExpenseControllerApi->listExpenseRevisions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **eid** | **String**|  | 

### Return type

[**BuiltList&lt;ExpenseRevisionView&gt;**](ExpenseRevisionView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listExpenses**
> PageResponseExpenseView listExpenses(gid, page, size, fromDate, toDate, memberId)



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getExpenseControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final int page = 56; // int | 
final int size = 56; // int | 
final Date fromDate = 2013-10-20; // Date | 
final Date toDate = 2013-10-20; // Date | 
final String memberId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.listExpenses(gid, page, size, fromDate, toDate, memberId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ExpenseControllerApi->listExpenses: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 20]
 **fromDate** | **Date**|  | [optional] 
 **toDate** | **Date**|  | [optional] 
 **memberId** | **String**|  | [optional] 

### Return type

[**PageResponseExpenseView**](PageResponseExpenseView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **previewExpense**
> ExpensePreview previewExpense(gid, expenseCommand)

Preview an expense split without saving it

Same body as create. Returns the computed total, charges and per-member breakdown, and payersTotalMatches. Persists nothing. Itemized-only totals are null for EQUAL/EXACT.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getExpenseControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final ExpenseCommand expenseCommand = {"expenseDate":"2026-10-18","payers":[{"amountMinor":10000,"memberId":"11111111-1111-1111-1111-111111111111"}],"splitType":"EQUAL","title":"Dinner","totalMinor":10000}; // ExpenseCommand | 

try {
    final response = api.previewExpense(gid, expenseCommand);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ExpenseControllerApi->previewExpense: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **expenseCommand** | [**ExpenseCommand**](ExpenseCommand.md)|  | 

### Return type

[**ExpensePreview**](ExpensePreview.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateExpense**
> ExpenseView updateExpense(gid, eid, ifMatch, expenseCommand)

Edit an expense (replaces payers, shares and items)

If-Match with the current version is required. Send the explicit participant list: members who joined later are never added silently. Writes a revision.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getExpenseControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String eid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String ifMatch = "1"; // String | The entity version from the last read, as returned in ETag, e.g. \"3\".
final ExpenseCommand expenseCommand = {"expenseDate":"2026-10-18","payers":[{"amountMinor":10000,"memberId":"11111111-1111-1111-1111-111111111111"}],"splitType":"EQUAL","title":"Dinner","totalMinor":10000}; // ExpenseCommand | 

try {
    final response = api.updateExpense(gid, eid, ifMatch, expenseCommand);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ExpenseControllerApi->updateExpense: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **eid** | **String**|  | 
 **ifMatch** | **String**| The entity version from the last read, as returned in ETag, e.g. \"3\". | 
 **expenseCommand** | [**ExpenseCommand**](ExpenseCommand.md)|  | 

### Return type

[**ExpenseView**](ExpenseView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

