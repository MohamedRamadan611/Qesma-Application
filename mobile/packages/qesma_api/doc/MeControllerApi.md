# qesma_api.api.MeControllerApi

## Load the API package
```dart
import 'package:qesma_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**changePassword**](MeControllerApi.md#changepassword) | **POST** /api/v1/me/password | 
[**getMe**](MeControllerApi.md#getme) | **GET** /api/v1/me | 
[**getPaymentHandles**](MeControllerApi.md#getpaymenthandles) | **GET** /api/v1/me/payment-handles | Your own InstaPay address and mobile-wallet number
[**updateMe**](MeControllerApi.md#updateme) | **PATCH** /api/v1/me | 
[**updatePaymentHandles**](MeControllerApi.md#updatepaymenthandles) | **PUT** /api/v1/me/payment-handles | Replace your payment handles


# **changePassword**
> TokenResponse changePassword(changePasswordRequest)



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getMeControllerApi();
final ChangePasswordRequest changePasswordRequest = ; // ChangePasswordRequest | 

try {
    final response = api.changePassword(changePasswordRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MeControllerApi->changePassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **changePasswordRequest** | [**ChangePasswordRequest**](ChangePasswordRequest.md)|  | 

### Return type

[**TokenResponse**](TokenResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMe**
> UserDto getMe()



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getMeControllerApi();

try {
    final response = api.getMe();
    print(response);
} catch on DioException (e) {
    print('Exception when calling MeControllerApi->getMe: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**UserDto**](UserDto.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPaymentHandles**
> PaymentHandlesView getPaymentHandles()

Your own InstaPay address and mobile-wallet number

Personal data. Co-members see a receiver's handles only on the balances transfers they pay (or as Owner/Admin).

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getMeControllerApi();

try {
    final response = api.getPaymentHandles();
    print(response);
} catch on DioException (e) {
    print('Exception when calling MeControllerApi->getPaymentHandles: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PaymentHandlesView**](PaymentHandlesView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateMe**
> UserDto updateMe(updateMeRequest)



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getMeControllerApi();
final UpdateMeRequest updateMeRequest = ; // UpdateMeRequest | 

try {
    final response = api.updateMe(updateMeRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MeControllerApi->updateMe: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateMeRequest** | [**UpdateMeRequest**](UpdateMeRequest.md)|  | 

### Return type

[**UserDto**](UserDto.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updatePaymentHandles**
> PaymentHandlesView updatePaymentHandles(updatePaymentHandlesRequest)

Replace your payment handles

A null, absent or blank field removes that handle. Wallet: Egyptian mobile (Arabic digits, spaces, dashes and +20 accepted), stored as 01XXXXXXXXX. InstaPay: name@bank, 3 to 60 ASCII characters, stored lower case.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getMeControllerApi();
final UpdatePaymentHandlesRequest updatePaymentHandlesRequest = ; // UpdatePaymentHandlesRequest | 

try {
    final response = api.updatePaymentHandles(updatePaymentHandlesRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MeControllerApi->updatePaymentHandles: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updatePaymentHandlesRequest** | [**UpdatePaymentHandlesRequest**](UpdatePaymentHandlesRequest.md)|  | 

### Return type

[**PaymentHandlesView**](PaymentHandlesView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

