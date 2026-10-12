import 'package:flutter/material.dart';

import '../../../../services/developer_mode_service.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';

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

  Future<void> _chooseFailure(
      BuildContext context, SimulatedFailure current) async {
    final choice = await showDialog<SimulatedFailure>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Fail the next submission at"),
        children: [
          for (final failure in SimulatedFailure.values)
            SimpleDialogOption(
              key: Key("simulate_failure_${failure.name}"),
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
