//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:qesma_api/src/date_serializer.dart';
import 'package:qesma_api/src/model/date.dart';

import 'package:qesma_api/src/model/auth_response.dart';
import 'package:qesma_api/src/model/balance_view.dart';
import 'package:qesma_api/src/model/change_password_request.dart';
import 'package:qesma_api/src/model/charges.dart';
import 'package:qesma_api/src/model/create_group_request.dart';
import 'package:qesma_api/src/model/create_member_request.dart';
import 'package:qesma_api/src/model/expense_command.dart';
import 'package:qesma_api/src/model/expense_preview.dart';
import 'package:qesma_api/src/model/expense_revision_view.dart';
import 'package:qesma_api/src/model/expense_view.dart';
import 'package:qesma_api/src/model/forgot_password_request.dart';
import 'package:qesma_api/src/model/google_login_request.dart';
import 'package:qesma_api/src/model/group_dto.dart';
import 'package:qesma_api/src/model/group_summary_dto.dart';
import 'package:qesma_api/src/model/invite_command.dart';
import 'package:qesma_api/src/model/invite_preview.dart';
import 'package:qesma_api/src/model/invite_view.dart';
import 'package:qesma_api/src/model/item_input.dart';
import 'package:qesma_api/src/model/item_view.dart';
import 'package:qesma_api/src/model/join_command.dart';
import 'package:qesma_api/src/model/join_request_view.dart';
import 'package:qesma_api/src/model/join_view.dart';
import 'package:qesma_api/src/model/joined_member.dart';
import 'package:qesma_api/src/model/login_request.dart';
import 'package:qesma_api/src/model/member_dto.dart';
import 'package:qesma_api/src/model/net.dart';
import 'package:qesma_api/src/model/page_response_expense_view.dart';
import 'package:qesma_api/src/model/page_response_group_summary_dto.dart';
import 'package:qesma_api/src/model/page_response_invite_view.dart';
import 'package:qesma_api/src/model/page_response_join_request_view.dart';
import 'package:qesma_api/src/model/page_response_settlement_view.dart';
import 'package:qesma_api/src/model/payer_input.dart';
import 'package:qesma_api/src/model/payer_view.dart';
import 'package:qesma_api/src/model/problem.dart';
import 'package:qesma_api/src/model/refresh_request.dart';
import 'package:qesma_api/src/model/register_request.dart';
import 'package:qesma_api/src/model/reset_password_request.dart';
import 'package:qesma_api/src/model/service_charge.dart';
import 'package:qesma_api/src/model/service_input.dart';
import 'package:qesma_api/src/model/settlement_command.dart';
import 'package:qesma_api/src/model/settlement_view.dart';
import 'package:qesma_api/src/model/share_input.dart';
import 'package:qesma_api/src/model/share_view.dart';
import 'package:qesma_api/src/model/tax_charge.dart';
import 'package:qesma_api/src/model/tax_input.dart';
import 'package:qesma_api/src/model/token_response.dart';
import 'package:qesma_api/src/model/transfer_view.dart';
import 'package:qesma_api/src/model/unclaimed.dart';
import 'package:qesma_api/src/model/update_group_request.dart';
import 'package:qesma_api/src/model/update_me_request.dart';
import 'package:qesma_api/src/model/update_member_request.dart';
import 'package:qesma_api/src/model/user_dto.dart';
import 'package:qesma_api/src/model/verify_email_request.dart';

part 'serializers.g.dart';

@SerializersFor([
  AuthResponse,
  BalanceView,
  ChangePasswordRequest,
  Charges,
  CreateGroupRequest,
  CreateMemberRequest,
  ExpenseCommand,
  ExpensePreview,
  ExpenseRevisionView,
  ExpenseView,
  ForgotPasswordRequest,
  GoogleLoginRequest,
  GroupDto,
  GroupSummaryDto,
  InviteCommand,
  InvitePreview,
  InviteView,
  ItemInput,
  ItemView,
  JoinCommand,
  JoinRequestView,
  JoinView,
  JoinedMember,
  LoginRequest,
  MemberDto,
  Net,
  PageResponseExpenseView,
  PageResponseGroupSummaryDto,
  PageResponseInviteView,
  PageResponseJoinRequestView,
  PageResponseSettlementView,
  PayerInput,
  PayerView,
  Problem,
  RefreshRequest,
  RegisterRequest,
  ResetPasswordRequest,
  ServiceCharge,
  ServiceInput,
  SettlementCommand,
  SettlementView,
  ShareInput,
  ShareView,
  TaxCharge,
  TaxInput,
  TokenResponse,
  TransferView,
  Unclaimed,
  UpdateGroupRequest,
  UpdateMeRequest,
  UpdateMemberRequest,
  UserDto,
  VerifyEmailRequest,
])
Serializers serializers = (_$serializers.toBuilder()
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ExpenseRevisionView)]),
        () => ListBuilder<ExpenseRevisionView>(),
      )
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer()))
    .build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
