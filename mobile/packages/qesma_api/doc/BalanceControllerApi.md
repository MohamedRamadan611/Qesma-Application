# qesma_api.api.BalanceControllerApi

## Load the API package
```dart
import 'package:qesma_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getBalances**](BalanceControllerApi.md#getbalances) | **GET** /api/v1/groups/{gid}/balances | Net balance per member and the simplified transfers that settle the group


# **getBalances**
> BalanceView getBalances(gid)

Net balance per member and the simplified transfers that settle the group

Positive net = the member is owed; negative = owes. Every member is listed, zeros included. Transfers are a deterministic greedy suggestion (spec 7.7), not a guaranteed minimum.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getBalanceControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getBalances(gid);
    print(response);
} catch on DioException (e) {
    print('Exception when calling BalanceControllerApi->getBalances: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 

### Return type

[**BalanceView**](BalanceView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

