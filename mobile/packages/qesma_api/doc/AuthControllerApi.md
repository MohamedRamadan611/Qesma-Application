# qesma_api.api.AuthControllerApi

## Load the API package
```dart
import 'package:qesma_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**refreshSession**](AuthControllerApi.md#refreshsession) | **POST** /api/v1/auth/refresh | 
[**signInWithGoogle**](AuthControllerApi.md#signinwithgoogle) | **POST** /api/v1/auth/google | 
[**signOut**](AuthControllerApi.md#signout) | **POST** /api/v1/auth/logout | 


# **refreshSession**
> TokenResponse refreshSession(refreshRequest)



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getAuthControllerApi();
final RefreshRequest refreshRequest = ; // RefreshRequest | 

try {
    final response = api.refreshSession(refreshRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthControllerApi->refreshSession: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **refreshRequest** | [**RefreshRequest**](RefreshRequest.md)|  | 

### Return type

[**TokenResponse**](TokenResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **signInWithGoogle**
> AuthResponse signInWithGoogle(googleLoginRequest)



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getAuthControllerApi();
final GoogleLoginRequest googleLoginRequest = ; // GoogleLoginRequest | 

try {
    final response = api.signInWithGoogle(googleLoginRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthControllerApi->signInWithGoogle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **googleLoginRequest** | [**GoogleLoginRequest**](GoogleLoginRequest.md)|  | 

### Return type

[**AuthResponse**](AuthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **signOut**
> signOut(refreshRequest)



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getAuthControllerApi();
final RefreshRequest refreshRequest = ; // RefreshRequest | 

try {
    api.signOut(refreshRequest);
} catch on DioException (e) {
    print('Exception when calling AuthControllerApi->signOut: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **refreshRequest** | [**RefreshRequest**](RefreshRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

