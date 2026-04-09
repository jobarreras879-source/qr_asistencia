import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_campaign.dart';
import '../theme/app_theme.dart';

class CampaignTooltipOverlay extends StatelessWidget {
  final AppCampaign campaign;
  final Rect? targetRect;
  final int currentStep;
  final int totalSteps;
  final bool isLastStep;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const CampaignTooltipOverlay({
    super.key,
    required this.campaign,
    required this.targetRect,
    required this.currentStep,
    required this.totalSteps,
    required this.isLastStep,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    const horizontalPadding = 16.0;
    final bubbleWidth = math.min(320.0, size.width - (horizontalPadding * 2));

    final resolvedRect = targetRect;
    final anchorCenter = resolvedRect?.center;
    final bubbleLeft = anchorCenter == null
        ? horizontalPadding
        : (anchorCenter.dx - bubbleWidth / 2)
            .clamp(horizontalPadding, size.width - bubbleWidth - horizontalPadding)
            .toDouble();

    final showBelow = resolvedRect == null
        ? true
        : resolvedRect.bottom + 220 < size.height;
    final bubbleTop = resolvedRect == null
        ? size.height * 0.24
        : showBelow
            ? math.min(resolvedRect.bottom + 18, size.height - 210)
            : math.max(24, resolvedRect.top - 190).toDouble();

    final arrowLeft = anchorCenter == null
        ? bubbleLeft + 36
        : (anchorCenter.dx - 10)
            .clamp(bubbleLeft + 24, bubbleLeft + bubbleWidth - 24)
            .toDouble();

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.58),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSkip,
              ),
            ),
            if (resolvedRect != null)
              Positioned(
                left: resolvedRect.left - 6,
                top: resolvedRect.top - 6,
                width: resolvedRect.width + 12,
                height: resolvedRect.height + 12,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.16),
                          blurRadius: 18,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: bubbleLeft,
              top: bubbleTop,
              width: bubbleWidth,
              child: _TooltipCard(
                campaign: campaign,
                currentStep: currentStep,
                totalSteps: totalSteps,
                isLastStep: isLastStep,
                onNext: onNext,
                onSkip: onSkip,
              ),
            ),
            if (resolvedRect != null)
              Positioned(
                left: arrowLeft,
                top: showBelow ? bubbleTop - 10 : bubbleTop + 152,
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TooltipCard extends StatelessWidget {
  final AppCampaign campaign;
  final int currentStep;
  final int totalSteps;
  final bool isLastStep;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _TooltipCard({
    required this.campaign,
    required this.currentStep,
    required this.totalSteps,
    required this.isLastStep,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Paso $currentStep de $totalSteps',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onSkip,
                splashRadius: 18,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            campaign.title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            campaign.body,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onSkip,
                child: Text(
                  'Omitir',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onNext,
                child: Text(isLastStep ? 'Entendido' : 'Siguiente'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
