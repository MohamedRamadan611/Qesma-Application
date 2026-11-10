# qesma_api.api.PasswordAuthControllerApi

## Load the API package
```dart
import 'package:qesma_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**forgotPassword**](PasswordAuthControllerApi.md#forgotpassword) | **POST** /api/v1/auth/password/forgot | 
[**registerWithPassword**](PasswordAuthControllerApi.md#registerwithpassword) | **POST** /api/v1/auth/register | 
[**resendEmailVerification**](PasswordAuthControllerApi.md#resendemailverification) | **POST** /api/v1/auth/email/verify/resend | 
[**resetPassword**](PasswordAuthControllerApi.md#resetpassword) | **POST** /api/v1/auth/password/reset | 
[**signInWithPassword**](PasswordAuthControllerApi.md#signinwithpassword) | **POST** /api/v1/auth/login | 
[**verifyEmail**](PasswordAuthControllerApi.md#verifyemail) | **POST** /api/v1/auth/email/verify | 


# **forgotPassword**
> forgotPassword(forgotPasswordRequest)



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getPasswordAuthControllerApi();
final ForgotPasswordRequest forgotPasswordRequest = ; // ForgotPasswordRequest | 

try {
    api.forgotPassword(forgotPasswordRequest);
} catch on DioException (e) {
    print('Exception when calling PasswordAuthControllerApi->forgotPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **forgotPasswordRequest** | [**ForgotPasswordRequest**](ForgotPasswordRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **registerWithPassword**
> AuthResponse registerWithPassword(registerRequest)



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getPasswordAuthControllerApi();
final RegisterRequest registerRequest = ; // RegisterRequest | 

try {
    final response = api.registerWithPassword(registerRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PasswordAuthControllerApi->registerWithPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **registerRequest** | [**RegisterRequest**](RegisterRequest.md)|  | 

### Return type

[**AuthResponse**](AuthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **resendEmailVerification**
> resendEmailVerification()



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getPasswordAuthControllerApi();

try {
    api.resendEmailVerification();
} catch on DioException (e) {
    print('Exception when calling PasswordAuthControllerApi->resendEmailVerification: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **resetPassword**
> resetPassword(resetPasswordRequest)



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getPasswordAuthControllerApi();
final ResetPasswordRequest resetPasswordRequest = ; // ResetPasswordRequest | 

try {
    api.resetPassword(resetPasswordRequest);
} catch on DioException (e) {
    print('Exception when calling PasswordAuthControllerApi->resetPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **resetPasswordRequest** | [**ResetPasswordRequest**](ResetPasswordRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **signInWithPassword**
> AuthResponse signInWithPassword(loginRequest)



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getPasswordAuthControllerApi();
final LoginRequest loginRequest = ; // LoginRequest | 

try {
    final response = api.signInWithPassword(loginRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PasswordAuthControllerApi->signInWithPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **loginRequest** | [**LoginRequest**](LoginRequest.md)|  | 

### Return type

[**AuthResponse**](AuthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **verifyEmail**
> verifyEmail(verifyEmailRequest)



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getPasswordAuthControllerApi();
final VerifyEmailRequest verifyEmailRequest = ; // VerifyEmailRequest | 

try {
    api.verifyEmail(verifyEmailRequest);
} catch on DioException (e) {
    print('Exception when calling PasswordAuthControllerApi->verifyEmail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **verifyEmailRequest** | [**VerifyEmailRequest**](VerifyEmailRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

