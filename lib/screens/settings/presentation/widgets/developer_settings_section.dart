import 'package:flutter/material.dart';

import '../../../../services/developer_mode_service.dart';
import '../pages/failed_submissions.dart';
import '../pages/network_sweep_page.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';
import '../../../../theme/dialogs/pop_ups.dart';

/// The Settings section shown while developer mode is on: a switch to turn
/// it off and testing tools such as simulating a submission failure.
class DeveloperSettingsSection extends StatelessWidget {
  const DeveloperSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final developerMode = DeveloperModeService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Developer",
          style: CustomTypography()
              .titleLarge(color: CustomColors.textNormalContent),
        ),
        const SizedBox(height: 12),
        Material(
          color: CustomColors.fillWhite,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: CustomColors.productBorderNormal),
          ),
          child: Column(
            children: [
              _tile(
                icon: Icons.developer_mode_rounded,
                title: "Developer mode",
                subtitle: "Shows detailed error information for testing.",
                trailing: Switch.adaptive(
                  key: const Key("developer_mode_switch"),
                  value: true,
                  activeTrackColor: CustomColors.productNormal,
                  onChanged: (value) {
                    if (!value) developerMode.disable();
                  },
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              ValueListenableBuilder<SimulatedFailure>(
                valueListenable: developerMode.simulatedFailure,
                builder: (context, failure, _) => _tile(
                  key: const Key("simulate_failure_tile"),
                  icon: Icons.error_outline_rounded,
                  title: "Simulate submission failure",
                  subtitle: failure == SimulatedFailure.none
                      ? "Off"
                      : "Next submission fails at: ${failure.label}",
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: CustomColors.midGrey),
                  onTap: () => _chooseFailure(context, failure),
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              ValueListenableBuilder<bool>(
                valueListenable: developerMode.skipConnectivityCheck,
                builder: (context, skip, _) => _tile(
                  icon: Icons.wifi_off_rounded,
                  title: "Skip connectivity check",
                  subtitle: skip
                      ? "Submits straight away without checking for internet"
                      : "Off",
                  trailing: Switch.adaptive(
                    key: const Key("skip_connectivity_switch"),
                    value: skip,
                    activeTrackColor: CustomColors.productNormal,
                    onChanged: (value) => _setSkipConnectivityCheck(
                        context, developerMode, value),
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              _tile(
                key: const Key("failed_submissions_tile"),
                icon: Icons.history_rounded,
                title: "Failed submissions",
                subtitle: "Recent failures on this device, with their traces.",
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: CustomColors.midGrey),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FailedSubmissionsPage()),
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              _tile(
                key: const Key("network_sweep_tile"),
                icon: Icons.network_check_rounded,
                title: "Run network sweep",
                subtitle: "Full check of this device's internet connection.",
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: CustomColors.midGrey),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NetworkSweepPage()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _tile({
    Key? key,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Row(
          spacing: 12,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const ShapeDecoration(
                  shape: CircleBorder(),
                  color: CustomColors.productLightBackground),
              child: Icon(icon, color: CustomColors.productNormal, size: 24),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: CustomTypography().bodyLarge(
                        color: CustomColors.productNormal,
                        weight: FontWeight.w500),
                  ),
                  Text(
                    subtitle,
                    style: CustomTypography()
                        .bodyMedium(color: CustomColors.textSecondaryContent),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  /// Turning the check off asks for confirmation first; turning it back on
  /// does not.
  Future<void> _setSkipConnectivityCheck(BuildContext context,
      DeveloperModeService developerMode, bool skip) async {
    if (skip) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => const DeletePopUp(
          title: "Skip connectivity check?",
          subheader:
              "Submissions will be sent without checking for internet first, "
              "and the homepage will stop showing the offline card. Without "
              "a connection, you'll see the submission error page instead of "
              "the no-internet screen. The entry stays on the device either "
              "way.",
          confirmText: "Skip check",
          confirmKey: Key("confirm_skip_connectivity"),
        ),
      );
      if (confirmed != true) return;
    }
    await developerMode.setSkipConnectivityCheck(skip);
  }

  Future<void> _chooseFailure(
      BuildContext context, SimulatedFailure current) async {
    final choice = await showDialog<SimulatedFailure>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: CustomColors.fillWhite,
        surfaceTintColor: CustomColors.fillWhite,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Colors.grey, width: 1)),
        titlePadding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        title: Text(
          "Fail the next submission at",
          style: CustomTypography().headlineMedium(),
          textAlign: TextAlign.center,
        ),
        children: [
          for (final failure in SimulatedFailure.values)
            SimpleDialogOption(
              key: Key("simulate_failure_${failure.name}"),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              onPressed: () => Navigator.pop(context, failure),
              child: Row(
                spacing: 12,
                children: [
                  Icon(
                    failure == current
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: CustomColors.productNormal,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(failure.label,
                            style: CustomTypography().bodyLarge(
                                color: CustomColors.textNormalContent)),
                        Text(failure.description,
                            style: CustomTypography().bodyMedium(
                                color: CustomColors.textSecondaryContent)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    if (choice != null) DeveloperModeService().simulateNextFailure(choice);
  }
}
