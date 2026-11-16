# qesma_api.api.NotificationPrefsControllerApi

## Load the API package
```dart
import 'package:qesma_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**updateGroupNotificationPrefs**](NotificationPrefsControllerApi.md#updategroupnotificationprefs) | **PUT** /api/v1/groups/{gid}/notification-prefs | Mute or unmute one group for yourself
[**updateNotificationPrefs**](NotificationPrefsControllerApi.md#updatenotificationprefs) | **PUT** /api/v1/me/notification-prefs | Switch all your notifications on or off


# **updateGroupNotificationPrefs**
> GroupNotificationPrefsView updateGroupNotificationPrefs(gid, updateGroupNotificationPrefsRequest)

Mute or unmute one group for yourself

muted=true: you get no new notification from this group, reminders and disputes included. The group activity feed still shows everything. Any active member may do this for themselves.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getNotificationPrefsControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final UpdateGroupNotificationPrefsRequest updateGroupNotificationPrefsRequest = ; // UpdateGroupNotificationPrefsRequest | 

try {
    final response = api.updateGroupNotificationPrefs(gid, updateGroupNotificationPrefsRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationPrefsControllerApi->updateGroupNotificationPrefs: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **updateGroupNotificationPrefsRequest** | [**UpdateGroupNotificationPrefsRequest**](UpdateGroupNotificationPrefsRequest.md)|  | 

### Return type

[**GroupNotificationPrefsView**](GroupNotificationPrefsView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateNotificationPrefs**
> NotificationPrefsView updateNotificationPrefs(updateNotificationPrefsRequest)

Switch all your notifications on or off

enabled=false: you get no new notification from any group, reminders and disputes included. Activity feeds still show everything. Notifications you already have are kept; switching back on does not backfill what you missed.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getNotificationPrefsControllerApi();
final UpdateNotificationPrefsRequest updateNotificationPrefsRequest = ; // UpdateNotificationPrefsRequest | 

try {
    final response = api.updateNotificationPrefs(updateNotificationPrefsRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationPrefsControllerApi->updateNotificationPrefs: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateNotificationPrefsRequest** | [**UpdateNotificationPrefsRequest**](UpdateNotificationPrefsRequest.md)|  | 

### Return type

[**NotificationPrefsView**](NotificationPrefsView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

