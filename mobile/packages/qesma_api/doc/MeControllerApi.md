# qesma_api.api.MeControllerApi

## Load the API package
```dart
import 'package:qesma_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getMe**](MeControllerApi.md#getme) | **GET** /api/v1/me | 
[**updateMe**](MeControllerApi.md#updateme) | **PATCH** /api/v1/me | 


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

