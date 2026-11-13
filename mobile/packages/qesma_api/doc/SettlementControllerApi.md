# qesma_api.api.SettlementControllerApi

## Load the API package
```dart
import 'package:qesma_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**cancelSettlement**](SettlementControllerApi.md#cancelsettlement) | **POST** /api/v1/groups/{gid}/settlements/{sid}/cancel | Cancel (the payer, or an Owner/Admin); replaces the Phase 1 delete
[**confirmSettlement**](SettlementControllerApi.md#confirmsettlement) | **POST** /api/v1/groups/{gid}/settlements/{sid}/confirm | Confirm \&quot;received\&quot; (the receiver, or an Owner/Admin who is not the payer)
[**createSettlement**](SettlementControllerApi.md#createsettlement) | **POST** /api/v1/groups/{gid}/settlements | Declare or record a settlement (a real-world payment between two members)
[**disputeSettlement**](SettlementControllerApi.md#disputesettlement) | **POST** /api/v1/groups/{gid}/settlements/{sid}/dispute | Dispute \&quot;not received\&quot; (the receiver only)
[**listSettlements**](SettlementControllerApi.md#listsettlements) | **GET** /api/v1/groups/{gid}/settlements | List settlements, newest first (cancelled ones included)


# **cancelSettlement**
> SettlementView cancelSettlement(gid, sid)

Cancel (the payer, or an Owner/Admin); replaces the Phase 1 delete

PENDING or DISPUTED -> CANCELLED; the row stays in the history. Repeating it returns the current settlement unchanged. 409 INVALID_STATE_TRANSITION from CONFIRMED.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getSettlementControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String sid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.cancelSettlement(gid, sid);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SettlementControllerApi->cancelSettlement: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **sid** | **String**|  | 

### Return type

[**SettlementView**](SettlementView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **confirmSettlement**
> SettlementView confirmSettlement(gid, sid)

Confirm \"received\" (the receiver, or an Owner/Admin who is not the payer)

PENDING or DISPUTED -> CONFIRMED. Repeating it returns the current settlement unchanged. 409 INVALID_STATE_TRANSITION from CANCELLED.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getSettlementControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String sid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.confirmSettlement(gid, sid);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SettlementControllerApi->confirmSettlement: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **sid** | **String**|  | 

### Return type

[**SettlementView**](SettlementView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createSettlement**
> SettlementView createSettlement(gid, idempotencyKey, settlementCommand)

Declare or record a settlement (a real-world payment between two members)

Idempotency-Key (UUID) is required. amountMinor is in piasters, 1 to 10^12. The status is decided by the server: the payer declares (PENDING, to a member with an account); the receiver or an Owner/Admin recording it makes it CONFIRMED (Owner/Admin on behalf: recordedByAdmin). 403 for a member recording a payment between two others or to a member without an account.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getSettlementControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Client-generated UUID, one per create action. Reuse the same key when retrying the SAME action: the stored answer is returned (header Idempotency-Replayed: true). Keys are kept 24 hours.
final SettlementCommand settlementCommand = {"amountMinor":8000,"fromMemberId":"22222222-2222-2222-2222-222222222222","note":"Cash at the hotel","settledOn":"2026-10-20","toMemberId":"11111111-1111-1111-1111-111111111111"}; // SettlementCommand | 

try {
    final response = api.createSettlement(gid, idempotencyKey, settlementCommand);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SettlementControllerApi->createSettlement: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **idempotencyKey** | **String**| Client-generated UUID, one per create action. Reuse the same key when retrying the SAME action: the stored answer is returned (header Idempotency-Replayed: true). Keys are kept 24 hours. | 
 **settlementCommand** | [**SettlementCommand**](SettlementCommand.md)|  | 

### Return type

[**SettlementView**](SettlementView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **disputeSettlement**
> SettlementView disputeSettlement(gid, sid)

Dispute \"not received\" (the receiver only)

PENDING -> DISPUTED. Repeating it returns the current settlement unchanged. 409 INVALID_STATE_TRANSITION from CONFIRMED or CANCELLED.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getSettlementControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String sid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.disputeSettlement(gid, sid);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SettlementControllerApi->disputeSettlement: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **sid** | **String**|  | 

### Return type

[**SettlementView**](SettlementView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listSettlements**
> PageResponseSettlementView listSettlements(gid, status, page, size)

List settlements, newest first (cancelled ones included)

Optional repeatable filter status=PENDING|CONFIRMED|DISPUTED|CANCELLED; without it every status is listed. Only CONFIRMED settlements move balances.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getSettlementControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final BuiltList<String> status = ; // BuiltList<String> | 
final int page = 56; // int | 
final int size = 56; // int | 

try {
    final response = api.listSettlements(gid, status, page, size);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SettlementControllerApi->listSettlements: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **status** | [**BuiltList&lt;String&gt;**](String.md)|  | [optional] 
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 20]

### Return type

[**PageResponseSettlementView**](PageResponseSettlementView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

