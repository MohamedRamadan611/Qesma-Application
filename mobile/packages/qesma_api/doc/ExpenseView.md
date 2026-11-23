# qesma_api.model.ExpenseView

## Load the model package
```dart
import 'package:qesma_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**category** | **String** |  | 
**charges** | [**Charges**](Charges.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**expenseDate** | [**Date**](Date.md) |  | 
**groupId** | **String** |  | 
**id** | **String** |  | 
**items** | [**BuiltList&lt;ItemView&gt;**](ItemView.md) |  | [optional] 
**paidFromPool** | **bool** |  | 
**payers** | [**BuiltList&lt;PayerView&gt;**](PayerView.md) |  | 
**periodFrom** | [**Date**](Date.md) |  | [optional] 
**periodTo** | [**Date**](Date.md) |  | [optional] 
**shares** | [**BuiltList&lt;ShareView&gt;**](ShareView.md) |  | 
**splitType** | **String** |  | 
**title** | **String** |  | 
**totalMinor** | **int** | Integer minor units (piasters: 1 EGP = 100). Never a decimal. | 
**version** | **int** |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


