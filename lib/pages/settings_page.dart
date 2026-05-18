import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storage_service.dart';
import '../constants/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '설정',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _SettingsItem(
            label: '개인정보처리방침',
            onTap: () => _launchUrl(
              context,
              'https://lilysoomin.notion.site/352a557ac58a801f94f5ff303d9a59ed',
            ),
          ),
          _SettingsItem(
            label: '오픈소스 라이선스',
            onTap: () => showLicensePage(
              context: context,
              applicationName: '헬스몽과부하',
              applicationVersion: '1.0.0',
            ),
          ),
          _SettingsItem(label: '데이터 관리', onTap: () => _showDataModal(context)),
          _SettingsItem(
            label: '카카오톡 채팅 문의',
            onTap: () =>
                _launchUrl(context, 'https://open.kakao.com/me/healthmong'),
          ),
          _SettingsItem(
            label: '버전 정보',
            trailing: const Text(
              'v1.0.0',
              style: TextStyle(fontSize: 14, color: AppColors.textHint),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('링크를 열 수 없습니다')));
      }
    }
  }

  void _showDataModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DataManagementModal(parentContext: context),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsItem({required this.label, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color.fromARGB(255, 231, 233, 236)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              trailing ??
                  (onTap != null
                      ? const Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AppColors.textHint,
                        )
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataManagementModal extends StatelessWidget {
  final BuildContext parentContext;

  const _DataManagementModal({required this.parentContext});

  Future<void> _exportData(BuildContext context) async {
    try {
      final storage = StorageService();
      final jsonData = storage.exportAllData();
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toString().substring(0, 10);
      final file = File('${directory.path}/metamong_backup_$timestamp.json');
      await file.writeAsString(jsonData);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '헬스몽 과부하 백업',
        text: '운동 기록 백업 파일',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('데이터를 내보냈습니다')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('내보내기 실패: $e')));
      }
    }
  }

  Future<void> _deleteAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('데이터 삭제'),
        content: const Text('모든 운동 기록, 루틴, 북마크가 삭제됩니다.\n삭제 후 복구할 수 없습니다.\n\n계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final storage = StorageService();
    await storage.deleteAllData();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 데이터가 삭제되었습니다')),
      );
    }
  }

  Future<void> _importData(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('클라우드 파일은 지원하지 않습니다. 기기에 저장된 파일을 선택해주세요.'),
            ),
          );
        }
        return;
      }

      final file = File(path);
      final jsonString = await file.readAsString();

      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('데이터 가져오기'),
          content: const Text('기존 데이터를 모두 덮어씁니다.\n계속하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                '취소',
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                '가져오기',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final storage = StorageService();
      final counts = await storage.importAllData(jsonString);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '가져오기 완료: 운동 ${counts['exercises']}개, '
              '기록 ${counts['records']}개, 루틴 ${counts['routines']}개',
            ),
          ),
        );
      }
    } on FormatException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('가져오기 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            '데이터 관리',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '헬스몽 과부하는 사용자 데이터를 저장하지 않습니다.핸드폰 기기 변경시 반드시 안전하게 데이터를 저장해주세요.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _exportData(parentContext);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '데이터 내보내기',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _importData(parentContext);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Center(
                child: Text(
                  '데이터 불러오기',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _deleteAllData(parentContext);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Center(
                child: Text(
                  '데이터 삭제',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
