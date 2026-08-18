import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_cloud_health/models/attachment.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/models/period_log.dart';
import 'package:open_cloud_health/repositories/attachment_repository.dart';
import 'package:open_cloud_health/repositories/history_repository.dart';
import 'package:open_cloud_health/repositories/period_repository.dart';
import 'package:open_cloud_health/repositories/checkups_repository.dart';
import 'package:open_cloud_health/services/file_service.dart';
import 'package:open_cloud_health/utils/result.dart';

class HistoryNotifier extends FamilyAsyncNotifier<List<HistoryEvent>, String> {
  HistoryRepository get _repository => ref.read(historyRepositoryProvider);
  AttachmentRepository get _attachmentRepository =>
      ref.read(attachmentRepositoryProvider);
  FileService get _fileService => ref.read(fileServiceProvider);

  @override
  Future<List<HistoryEvent>> build(String arg) async {
    final sub = ref.watch(historyRepositoryProvider).watchEvents(arg).listen((_) async {
      state = await AsyncValue.guard(() => _fetchEvents(arg));
    });
    ref.onDispose(sub.cancel);

    return _fetchEvents(arg);
  }

  Future<Result<String, Exception>> saveEventWithAttachments({
    String? id,
    required String profileId,
    required String title,
    required String description,
    required DateTime date,
    required EventType eventType,
    required bool hasTime,
    String? provider,
    String? facility,
    required List<Attachment> attachments,
  }) async {
    try {
      String historyId;
      final event = HistoryEvent(
        id: id,
        profileId: profileId,
        title: title,
        description: description,
        date: date,
        eventType: eventType,
        hasTime: hasTime,
        provider: provider,
        facility: facility,
        attachmentCount: attachments.length,
      );

      if (id == null) {
        await _repository.addEvent(event);
        historyId = event.id;
      } else {
        await _repository.updateEvent(event);
        historyId = id;
      }

      // Handle attachments
      final dbAttachments = await _attachmentRepository.getAttachments(historyId);
      
      // Find attachments to remove
      final attachmentsToRemove = dbAttachments.where((dbAtt) =>
          attachments.where((att) => att.id == dbAtt.id).isEmpty).toList();
      
      for (final att in attachmentsToRemove) {
        await _attachmentRepository.deleteAttachments([att.id]);
        await _fileService.deleteAttachment(historyId, att.filename);
      }

      // Find attachments to add
      final attachmentsToAdd = attachments.where((att) =>
          dbAttachments.where((dbAtt) => dbAtt.id == att.id).isEmpty).toList();

      for (final att in attachmentsToAdd) {
        final updatedAtt = att.copyWith(historyId: historyId);
        await _attachmentRepository.insertAttachment(updatedAtt);
        if (updatedAtt.tempPath.isNotEmpty) {
          await _fileService.saveAttachment(
            historyId,
            File(updatedAtt.tempPath),
            updatedAtt.filename,
          );
        }
      }

      await refreshEvents();
      return Success(historyId);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<List<HistoryEvent>> _fetchEvents(String profileId) async {
    try {
      final historyEvents = await _repository.fetchEvents(profileId);

      // Fetch Period logs
      final periodRepo = ref.read(periodRepositoryProvider);
      final cycles = await periodRepo.getCycles(profileId);
      for (final cycle in cycles) {
        final logs = await periodRepo.getLogsForCycle(cycle.id);
        if (logs.isEmpty) continue;

        // Sort logs by date ascending
        logs.sort((a, b) => a.date.compareTo(b.date));

        // Group consecutive days where the gap is <= 1 day
        final List<List<PeriodLog>> groups = [];
        List<PeriodLog> currentGroup = [];

        for (final log in logs) {
          if (currentGroup.isEmpty) {
            currentGroup.add(log);
          } else {
            final lastLog = currentGroup.last;
            final lastDate = DateTime(lastLog.date.year, lastLog.date.month, lastLog.date.day);
            final thisDate = DateTime(log.date.year, log.date.month, log.date.day);
            final difference = thisDate.difference(lastDate).inDays;

            if (difference <= 1) {
              currentGroup.add(log);
            } else {
              groups.add(currentGroup);
              currentGroup = [log];
            }
          }
        }
        if (currentGroup.isNotEmpty) {
          groups.add(currentGroup);
        }

        // Add a HistoryEvent for each consecutive group
        for (final group in groups) {
          if (group.isEmpty) continue;

          final startLog = group.first;
          final endLog = group.last;
          final startDate = startLog.date;
          final endDate = endLog.date;

          final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
          final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
          final duration = endOnly.difference(startOnly).inDays + 1;

          final String title = duration > 1 ? 'Period ($duration days)' : 'Period';

          // Format Date Range beautifully
          String durationText;
          if (duration > 1) {
            final monthDayFormat = DateFormat('MMMM d');
            final dayOnlyFormat = DateFormat('d');
            final fullDateFormat = DateFormat('MMMM d, yyyy');

            if (startDate.year == endDate.year) {
              if (startDate.month == endDate.month) {
                durationText = '$duration consecutive days: ${monthDayFormat.format(startDate)} – ${dayOnlyFormat.format(endDate)}, ${startDate.year}';
              } else {
                durationText = '$duration consecutive days: ${monthDayFormat.format(startDate)} – ${monthDayFormat.format(endDate)}, ${startDate.year}';
              }
            } else {
              durationText = '$duration consecutive days: ${fullDateFormat.format(startDate)} – ${fullDateFormat.format(endDate)}';
            }
          } else {
            durationText = DateFormat('MMMM d, yyyy').format(startDate);
          }

          // Flow levels
          final flows = group.map((l) => l.flowLevel).whereType<FlowLevel>().toList();
          final flowText = flows.isNotEmpty 
              ? 'Flow: ${flows.map((f) => f.name).toSet().join(', ')}' 
              : 'Flow: None';

          // Moods
          final moodsSet = group.expand((l) => l.moods).toSet();
          final moodText = moodsSet.isNotEmpty 
              ? 'Moods: ${moodsSet.map((m) => m.name).join(', ')}' 
              : null;

          // Physical Symptoms
          final symptomsSet = group.expand((l) => l.physicalSymptoms).toSet();
          final symptomText = symptomsSet.isNotEmpty 
              ? 'Symptoms: ${symptomsSet.map((s) => s.name).join(', ')}' 
              : null;

          final descriptionParts = [
            durationText,
            flowText,
            if (moodText != null) moodText,
            if (symptomText != null) symptomText,
          ];
          final description = descriptionParts.join('\n');

          historyEvents.add(
            HistoryEvent(
              id: startLog.id,
              profileId: profileId,
              title: title,
              description: description,
              date: startLog.date,
              eventType: EventType.period,
              hasTime: false,
            )
          );
        }
      }

      // Fetch Checkup logs
      final checkupRepo = ref.read(checkupsRepositoryProvider);
      final checkups = await checkupRepo.loadCheckups(profileId);
      final checkupMap = {for (var c in checkups) c.id: c.name};
      final checkupLogs = await checkupRepo.loadAllLogsForProfile(profileId);
      for (final log in checkupLogs) {
        final checkupName = checkupMap[log.checkupId] ?? 'Unknown Checkup';
        
        final descriptionParts = [
          'Completed checkup',
          if (log.notes != null && log.notes!.trim().isNotEmpty) 'Notes: ${log.notes}',
        ];
        
        historyEvents.add(
          HistoryEvent(
            id: log.id,
            profileId: profileId,
            title: 'Checkup: $checkupName',
            description: descriptionParts.join('\n\n'),
            date: log.dateCompleted,
            eventType: EventType.checkup,
            provider: log.doctorName,
            facility: log.location,
          )
        );
      }

      historyEvents.sort((a, b) => b.date.compareTo(a.date));
      return historyEvents;
    } catch (error) {
      debugPrint('Error: $error');
      rethrow;
    }
  }

  Future<Result<void, Exception>> deleteEvent(String id) async {
    try {
      await _repository.deleteEvent(id);
      // Also delete attachments and files
      final attachments = await _attachmentRepository.getAttachments(id);
      for (final att in attachments) {
        await _fileService.deleteAttachment(id, att.filename);
      }
      await _attachmentRepository
          .deleteAttachments(attachments.map((e) => e.id).toList());

      await refreshEvents();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<void> refreshEvents() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchEvents(arg));
  }
}

final historyProvider =
    AsyncNotifierProvider.family<HistoryNotifier, List<HistoryEvent>, String>(
        HistoryNotifier.new);
