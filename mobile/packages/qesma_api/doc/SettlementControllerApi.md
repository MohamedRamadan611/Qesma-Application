# qesma_api.api.SettlementControllerApi

## Load the API package
```dart
import 'package:qesma_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createSettlement**](SettlementControllerApi.md#createsettlement) | **POST** /api/v1/groups/{gid}/settlements | Record a settlement (a real-world payment between two members)
[**deleteSettlement**](SettlementControllerApi.md#deletesettlement) | **DELETE** /api/v1/groups/{gid}/settlements/{sid} | Delete a settlement (soft delete; its effect on balances is reversed)
[**listSettlements**](SettlementControllerApi.md#listsettlements) | **GET** /api/v1/groups/{gid}/settlements | List settlements, newest first (deleted ones are not listed)


# **createSettlement**
> SettlementView createSettlement(gid, idempotencyKey, settlementCommand)

Record a settlement (a real-world payment between two members)

Idempotency-Key (UUID) is required. amountMinor is in piasters, 1 to 10^12.

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

# **deleteSettlement**
> deleteSettlement(gid, sid)

Delete a settlement (soft delete; its effect on balances is reversed)

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getSettlementControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String sid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.deleteSettlement(gid, sid);
} catch on DioException (e) {
    print('Exception when calling SettlementControllerApi->deleteSettlement: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **sid** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listSettlements**
> PageResponseSettlementView listSettlements(gid, page, size)

List settlements, newest first (deleted ones are not listed)

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getSettlementControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final int page = 56; // int | 
final int size = 56; // int | 

try {
    final response = api.listSettlements(gid, page, size);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SettlementControllerApi->listSettlements: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
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

