import 'package:flutter/material.dart';

import '../../../../core/diagnostics/diagnostics_bundle.dart';
import '../../../../core/usecases/time_travel.dart';
import '../../../../core/utils/app_clock.dart';
import '../../../../services/developer_mode_service.dart';
import '../pages/failed_submissions.dart';
import '../pages/local_data_page.dart';
import '../pages/network_sweep_page.dart';
import '../pages/pending_submissions_page.dart';
import '../pages/time_travel_page.dart';
import 'developer_widgets.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';
import '../../../../theme/dialogs/pop_ups.dart';

/// The Settings section shown while developer mode is on: a switch to turn
/// it off and testing tools such as simulating a submission failure, time
/// travel and a diagnostics export.
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
                    if (!value) _disable(context, developerMode);
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
              const Divider(height: 1, thickness: 0.5),
              _tile(
                key: const Key("local_data_tile"),
                icon: Icons.storage_rounded,
                title: "Local data",
                subtitle:
                    "Protocol, studies and diaries stored on this device.",
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: CustomColors.midGrey),
                onTap: () => _open(context, const LocalDataPage()),
              ),
              const Divider(height: 1, thickness: 0.5),
              _tile(
                key: const Key("pending_submissions_tile"),
                icon: Icons.cloud_upload_outlined,
                title: "Pending submissions",
                subtitle: "Entries waiting to upload, with a retry button.",
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: CustomColors.midGrey),
                onTap: () => _open(context, const PendingSubmissionsPage()),
              ),
              const Divider(height: 1, thickness: 0.5),
              ValueListenableBuilder<Duration>(
                valueListenable: developerMode.timeTravel,
                builder: (context, offset, _) => _tile(
                  key: const Key("time_travel_tile"),
                  icon: Icons.schedule_rounded,
                  title: "Time travel",
                  subtitle: offset == Duration.zero
                      ? "Off"
                      : "App date: ${developerDateFormat.format(AppClock.now())}",
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: CustomColors.midGrey),
                  onTap: () => _open(context, const TimeTravelPage()),
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              Builder(
                builder: (context) => _tile(
                  key: const Key("export_diagnostics_tile"),
                  icon: Icons.ios_share_rounded,
                  title: "Export diagnostics",
                  subtitle:
                      "Share one file describing this device, for the study team.",
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: CustomColors.midGrey),
                  onTap: () => _exportDiagnostics(context),
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

  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (context) => page));

  /// Turns developer mode off. If time travel left anything behind, comes
  /// back to the present and repairs statuses first, since the page that
  /// does it is hidden once developer mode is off.
  Future<void> _disable(
      BuildContext context, DeveloperModeService developerMode) async {
    final timeTravel = TimeTravel();
    if (developerMode.isTimeTravelling || await timeTravel.hasSnapshot()) {
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => const DeletePopUp(
          title: "Turn off developer mode?",
          subheader: "Time travel is or was on. The app date goes back to "
              "today, and diary statuses changed while travelling are "
              "repaired.",
          confirmText: "Turn off",
          confirmKey: Key("confirm_disable_developer_mode"),
        ),
      );
      if (confirmed != true) return;
      await timeTravel.returnToPresent();
      await timeTravel.repair();
    }
    await developerMode.disable();
  }

  Future<void> _exportDiagnostics(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text("Preparing diagnostics…")));
    try {
      final file = await DiagnosticsBundle.write();
      messenger.hideCurrentSnackBar();
      await DiagnosticsBundle.share(file, origin: origin);
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text("Could not export diagnostics: $e")));
    }
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
