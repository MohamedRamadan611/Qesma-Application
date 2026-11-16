# qesma_api.api.ActivityControllerApi

## Load the API package
```dart
import 'package:qesma_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**listGroupActivity**](ActivityControllerApi.md#listgroupactivity) | **GET** /api/v1/groups/{gid}/activity | The group&#39;s activity feed, newest first (keyset pagination)


# **listGroupActivity**
> ActivityPage listGroupActivity(gid, limit, before)

The group's activity feed, newest first (keyset pagination)

Every ACTIVE member reads the whole history. limit: 1 to 50 (default 20). before: the opaque nextBefore of the previous page (422 if malformed). nextBefore is null on the last page. payload holds ids, a version and integer amounts only; subject is the expense title (EXPENSE_* events, also after the expense was deleted) or the member's name (member events), resolved at read time.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getActivityControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final int limit = 56; // int | 
final String before = before_example; // String | 

try {
    final response = api.listGroupActivity(gid, limit, before);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ActivityControllerApi->listGroupActivity: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **limit** | **int**|  | [optional] 
 **before** | **String**|  | [optional] 

### Return type

[**ActivityPage**](ActivityPage.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

