import { X, Copy, Trash2 } from 'lucide-react';
import { Campaign } from '../../data/mockCampaigns';
import { toast } from 'sonner@2.0.3';
import { useState } from 'react';
import { campaignService } from '../../services/campaignService';
import { ApiError } from '../../config/api';

interface CampaignDetailSheetProps {
  campaign: Campaign;
  onClose: () => void;
  onUpdate: (campaign: Campaign) => void;
  onDelete: (id: string) => void;
}

export function CampaignDetailSheet({ campaign, onClose, onUpdate, onDelete }: CampaignDetailSheetProps) {
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleCopy = (text: string) => {
    navigator.clipboard.writeText(text);
    toast.success('클립보드에 복사되었습니다.');
  };

  const handleDuplicate = async () => {
    try {
      setLoading(true);
      const duplicatedData = {
        key: `${campaign.key}_copy`,
        kind: campaign.kind,
        placement: campaign.placement,
        template: campaign.template,
        priority: campaign.priority,
        is_enabled: false,
        start_at: campaign.startAt, // ISO 문자열 형식
        end_at: campaign.endAt, // ISO 문자열 형식
        content: campaign.content,
        rules: [], // 기본값
        actions: [], // 기본값
      };
      const newCampaign = await campaignService.createCampaign(duplicatedData);
      onUpdate(newCampaign);
      toast.success('캠페인이 복제되었습니다.');
    } catch (err) {
      const errorMessage = err instanceof ApiError 
        ? `복제 실패: ${err.status} ${err.statusText}`
        : '캠페인 복제에 실패했습니다.';
      toast.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const handleToggleEnabled = async () => {
    try {
      setLoading(true);
      const updated = await campaignService.toggleCampaign(campaign.id, !campaign.isEnabled);
      onUpdate(updated);
      toast.success(`캠페인이 ${updated.isEnabled ? '활성화' : '비활성화'}되었습니다.`);
    } catch (err) {
      const errorMessage = err instanceof ApiError 
        ? `상태 변경 실패: ${err.status} ${err.statusText}`
        : '상태 변경에 실패했습니다.';
      toast.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const handleDisable = async () => {
    await handleToggleEnabled();
  };

  const handleDelete = () => {
    onDelete(campaign.id);
    setShowDeleteConfirm(false);
  };

  return (
    <>
      {/* Backdrop */}
      <div className="fixed inset-0 bg-black/50 z-50" onClick={onClose} />

      {/* Sheet */}
      <div className="fixed right-0 top-0 bottom-0 w-full max-w-2xl bg-white shadow-2xl z-50 overflow-y-auto">
        {/* Header */}
        <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between z-10">
          <h2 className="text-xl font-bold text-gray-900">캠페인 상세</h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-gray-600" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-6">
          {/* Key Info */}
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Campaign Key
              </label>
              <div className="flex items-center gap-2">
                <code className="flex-1 bg-gray-100 px-4 py-2 rounded-lg text-sm font-mono">
                  {campaign.key}
                </code>
                <button
                  onClick={() => handleCopy(campaign.key)}
                  className="p-2 hover:bg-gray-100 rounded-lg"
                >
                  <Copy className="w-4 h-4 text-gray-600" />
                </button>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Kind
                </label>
                <select
                  value={campaign.kind}
                  className="admin-input w-full"
                  disabled
                >
                  <option value="EVENT">EVENT</option>
                  <option value="NOTICE">NOTICE</option>
                  <option value="AD">AD</option>
                  <option value="MISSION">MISSION</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Placement
                </label>
                <select
                  value={campaign.placement}
                  className="admin-input w-full"
                  disabled
                >
                  <option value="HOME_MODAL">HOME_MODAL</option>
                  <option value="HOME_BANNER">HOME_BANNER</option>
                  <option value="NOTICE_CENTER">NOTICE_CENTER</option>
                  <option value="BENEFITS_PAGE">BENEFITS_PAGE</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Template
                </label>
                <input
                  type="text"
                  value={campaign.template}
                  className="admin-input w-full"
                  readOnly
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Priority
                </label>
                <input
                  type="number"
                  value={campaign.priority}
                  className="admin-input w-full"
                  readOnly
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                활성화 상태
              </label>
              <button
                onClick={handleToggleEnabled}
                disabled={loading}
                className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                  campaign.isEnabled ? 'bg-blue-500' : 'bg-gray-300'
                } disabled:opacity-50`}
              >
                <span
                  className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                    campaign.isEnabled ? 'translate-x-6' : 'translate-x-1'
                  }`}
                />
              </button>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  시작일
                </label>
                <input
                  type="text"
                  value={new Date(campaign.startAt).toLocaleString('ko-KR')}
                  className="admin-input w-full"
                  readOnly
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  종료일
                </label>
                <input
                  type="text"
                  value={new Date(campaign.endAt).toLocaleString('ko-KR')}
                  className="admin-input w-full"
                  readOnly
                />
              </div>
            </div>
          </div>

          {/* Content JSON */}
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">
              Content (JSON)
            </label>
            <pre className="bg-gray-900 text-green-400 p-4 rounded-lg text-xs font-mono overflow-x-auto">
              {JSON.stringify(campaign.content, null, 2)}
            </pre>
          </div>

          {/* Actions */}
          <div className="flex flex-wrap gap-2">
            <button
              onClick={handleDuplicate}
              disabled={loading}
              className="admin-btn px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 disabled:opacity-50"
            >
              {loading ? '처리 중...' : '복제'}
            </button>
            <button
              onClick={handleDisable}
              disabled={loading || !campaign.isEnabled}
              className="admin-btn px-4 py-2 bg-yellow-50 hover:bg-yellow-100 text-yellow-700 disabled:opacity-50"
            >
              비활성화
            </button>
            <button
              onClick={() => setShowDeleteConfirm(true)}
              className="admin-btn px-4 py-2 bg-red-50 hover:bg-red-100 text-red-600 flex items-center gap-2"
            >
              <Trash2 className="w-4 h-4" />
              삭제
            </button>
          </div>

          {/* Audit Notice */}
          <div className="text-xs text-yellow-600 bg-yellow-50 p-3 rounded-lg">
            ⚠️ 모든 변경사항은 로그로 기록됩니다.
          </div>
        </div>
      </div>

      {/* Delete Confirmation Modal */}
      {showDeleteConfirm && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-[60] p-4">
          <div className="bg-white rounded-2xl shadow-2xl max-w-md w-full p-6">
            <h3 className="text-lg font-bold text-gray-900 mb-2">캠페인 삭제</h3>
            <p className="text-sm text-gray-600 mb-6">
              정말로 이 캠페인을 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.
            </p>
            <div className="text-xs text-yellow-600 bg-yellow-50 p-3 rounded-lg mb-6">
              ⚠️ 이 작업은 로그로 기록됩니다.
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => setShowDeleteConfirm(false)}
                className="admin-btn flex-1 px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700"
              >
                취소
              </button>
              <button
                onClick={handleDelete}
                className="admin-btn flex-1 px-4 py-2 bg-red-500 hover:bg-red-600 text-white"
              >
                삭제
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}