# qesma_api.api.NotificationControllerApi

## Load the API package
```dart
import 'package:qesma_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getUnreadNotificationCount**](NotificationControllerApi.md#getunreadnotificationcount) | **GET** /api/v1/notifications/unread-count | How many of your notifications are unread
[**listNotifications**](NotificationControllerApi.md#listnotifications) | **GET** /api/v1/notifications | Your notifications, newest first (keyset pagination)
[**markNotificationsRead**](NotificationControllerApi.md#marknotificationsread) | **POST** /api/v1/notifications/read | Mark your notifications read


# **getUnreadNotificationCount**
> UnreadCount getUnreadNotificationCount()

How many of your notifications are unread

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getNotificationControllerApi();

try {
    final response = api.getUnreadNotificationCount();
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationControllerApi->getUnreadNotificationCount: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**UnreadCount**](UnreadCount.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listNotifications**
> NotificationPage listNotifications(limit, before)

Your notifications, newest first (keyset pagination)

limit: 1 to 50 (default 20). before: the opaque nextBefore of the previous page (422 if malformed). groupName is always present; actorName and subject only while you are still an ACTIVE member of that group. Notifications stay readable after you leave a group.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getNotificationControllerApi();
final int limit = 56; // int | 
final String before = before_example; // String | 

try {
    final response = api.listNotifications(limit, before);
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationControllerApi->listNotifications: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **limit** | **int**|  | [optional] 
 **before** | **String**|  | [optional] 

### Return type

[**NotificationPage**](NotificationPage.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markNotificationsRead**
> MarkReadResult markNotificationsRead(markReadRequest)

Mark your notifications read

Body: exactly one of ids (1 to 100 notification ids) or all: true (else 422). Ids that are unknown or belong to someone else are ignored (the answer is identical). marked counts the rows that changed now. Not a create: no Idempotency-Key, repeating it is harmless.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getNotificationControllerApi();
final MarkReadRequest markReadRequest = ; // MarkReadRequest | 

try {
    final response = api.markNotificationsRead(markReadRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationControllerApi->markNotificationsRead: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **markReadRequest** | [**MarkReadRequest**](MarkReadRequest.md)|  | 

### Return type

[**MarkReadResult**](MarkReadResult.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

