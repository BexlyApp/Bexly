import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/features/bank_links/data/services/tingee_link_service.dart';
import 'package:bexly/features/bank_links/domain/models/tingee_bank.dart';
import 'package:bexly/features/bank_links/presentation/riverpod/linked_accounts_provider.dart';

/// Account-info form for linking a Tingee VA. Submits create_va, then
/// switches to OTP entry, then calls confirm_va. On success refreshes
/// linkedAccountsProvider and closes the sheet.
Future<void> showLinkAccountFormSheet(
  BuildContext context, {
  required TingeeBank bank,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _LinkAccountFormSheet(bank: bank),
  );
}

class _LinkAccountFormSheet extends ConsumerStatefulWidget {
  const _LinkAccountFormSheet({required this.bank});
  final TingeeBank bank;

  @override
  ConsumerState<_LinkAccountFormSheet> createState() =>
      _LinkAccountFormSheetState();
}

enum _Step { form, otp, done }

class _LinkAccountFormSheetState extends ConsumerState<_LinkAccountFormSheet> {
  final _service = TingeeLinkService();
  final _formKey = GlobalKey<FormState>();
  final _accountNumber = TextEditingController();
  final _accountName = TextEditingController();
  final _identity = TextEditingController();
  final _mobile = TextEditingController();
  final _label = TextEditingController();
  final _otp = TextEditingController();

  _Step _step = _Step.form;
  bool _busy = false;
  String? _error;
  String? _confirmId;

  @override
  void dispose() {
    _accountNumber.dispose();
    _accountName.dispose();
    _identity.dispose();
    _mobile.dispose();
    _label.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await _service.createVa(
        bankBin: widget.bank.bin,
        accountNumber: _accountNumber.text.trim(),
        accountName: _accountName.text.trim(),
        identity: _identity.text.trim(),
        mobile: _mobile.text.trim(),
        label: _label.text.trim().isEmpty ? null : _label.text.trim(),
      );
      if (!r.isOk || r.confirmId == null) {
        throw Exception(r.message ?? 'Tingee từ chối yêu cầu (code ${r.code}).');
      }
      setState(() {
        _confirmId = r.confirmId;
        _step = _Step.otp;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitOtp() async {
    if (_confirmId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await _service.confirmVa(
        bankBin: widget.bank.bin,
        confirmId: _confirmId!,
        otpNumber: _otp.text.trim().isEmpty ? null : _otp.text.trim(),
      );
      if (!r.isOk) {
        throw Exception(r.message ?? 'Xác nhận thất bại (code ${r.code}).');
      }
      // Refresh the linked accounts list - Edge Function persisted the row.
      ref.invalidate(linkedAccountsProvider);
      setState(() => _step = _Step.done);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: media.viewInsets.bottom,
        left: AppSpacing.spacing20,
        right: AppSpacing.spacing20,
        top: AppSpacing.spacing8,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.bank.displayName, style: AppTextStyles.heading4),
              const Gap(AppSpacing.spacing4),
              Text(
                _stepCaption,
                style: AppTextStyles.body4.copyWith(color: AppColors.neutral600),
              ),
              const Gap(AppSpacing.spacing16),
              ..._stepBody(),
              if (_error != null) ...[
                const Gap(AppSpacing.spacing12),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.spacing12),
                  decoration: BoxDecoration(
                    color: AppColors.redAlpha10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: AppTextStyles.body4.copyWith(color: AppColors.red600),
                  ),
                ),
              ],
              const Gap(AppSpacing.spacing20),
            ],
          ),
        ),
      ),
    );
  }

  String get _stepCaption {
    switch (_step) {
      case _Step.form:
        return 'Nhập thông tin tài khoản chủ.';
      case _Step.otp:
        return 'Nhập mã OTP do ngân hàng gửi để xác nhận liên kết.';
      case _Step.done:
        return 'Đã liên kết. Giao dịch mới sẽ tự xuất hiện trong Bexly.';
    }
  }

  List<Widget> _stepBody() {
    switch (_step) {
      case _Step.form:
        return [
          Form(
            key: _formKey,
            child: Column(
              children: [
                _field(_accountNumber, 'Số tài khoản', keyboard: TextInputType.number),
                _field(_accountName, 'Họ tên chủ tài khoản'),
                _field(_identity, 'CMND/CCCD'),
                _field(_mobile, 'Số điện thoại đăng ký', keyboard: TextInputType.phone),
                _field(_label, 'Nhãn (tuỳ chọn) - vd "Lương"', required: false),
              ],
            ),
          ),
          const Gap(AppSpacing.spacing16),
          _primaryButton(label: 'Tiếp tục', onTap: _busy ? null : _submitForm),
        ];

      case _Step.otp:
        return [
          _field(
            _otp,
            'Mã OTP',
            keyboard: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const Gap(AppSpacing.spacing12),
          _primaryButton(label: 'Xác nhận', onTap: _busy ? null : _submitOtp),
          const Gap(AppSpacing.spacing8),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                      _step = _Step.form;
                      _error = null;
                    }),
            child: const Text('Sửa thông tin'),
          ),
        ];

      case _Step.done:
        return [
          Icon(Icons.check_circle, color: AppColors.green200, size: 56),
          const Gap(AppSpacing.spacing16),
          Text(
            'Đã liên kết tài khoản thành công.',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          ),
          const Gap(AppSpacing.spacing16),
          _primaryButton(
            label: 'Đóng',
            onTap: () => Navigator.of(context).pop(),
          ),
        ];
    }
  }

  Widget _field(
    TextEditingController c,
    String label, {
    TextInputType? keyboard,
    bool required = true,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
                ? 'Bắt buộc'
                : null
            : null,
      ),
    );
  }

  Widget _primaryButton({required String label, VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary500,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing12),
        ),
        child: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label),
      ),
    );
  }
}
