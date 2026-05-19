import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/attachment.dart';
import 'package:open_cloud_health/models/history_event.dart';
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
    return _fetchEvents(arg);
  }

  Future<Result<String, Exception>> saveEventWithAttachments({
    String? id,
    required String profileId,
    required String title,
    required String description,
    required DateTime date,
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
        for (final log in logs) {
          historyEvents.add(
            HistoryEvent(
              id: log.id,
              profileId: profileId,
              title: 'Period Log',
              description: 'Flow: ${log.flowLevel?.name ?? "Unknown"}, Moods: ${log.moods.length}, Symptoms: ${log.physicalSymptoms.length}',
              date: log.date,
              eventType: EventType.period,
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
        historyEvents.add(
          HistoryEvent(
            id: log.id,
            profileId: profileId,
            title: 'Checkup: $checkupName',
            description: 'Completed checkup',
            date: log.dateCompleted,
            eventType: EventType.checkup,
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
