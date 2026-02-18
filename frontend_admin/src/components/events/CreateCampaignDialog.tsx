import { useState } from 'react';
import { X } from 'lucide-react';
import { Campaign } from '../../data/mockCampaigns';
import { toast } from 'sonner@2.0.3';
import { campaignService } from '../../services/campaignService';
import { ApiError } from '../../config/api';

interface CreateCampaignDialogProps {
  onClose: () => void;
  onCreate: (campaign: Campaign) => void;
}

export function CreateCampaignDialog({ onClose, onCreate }: CreateCampaignDialogProps) {
  const [formData, setFormData] = useState({
    key: '',
    kind: 'EVENT' as 'EVENT' | 'NOTICE' | 'AD' | 'MISSION',
    placement: 'HOME_MODAL' as 'HOME_MODAL' | 'HOME_BANNER' | 'NOTICE_CENTER' | 'BENEFITS_PAGE',
    template: 'no_image' as 'image_top' | 'no_image' | 'product_spotlight' | 'mission_card',
    priority: 5,
    isEnabled: true,
    startAt: '',
    endAt: '',
    contentTitle: '',
    contentDescription: '',
    contentImageUrl: '',
    ctaText: '',
    ctaDeeplink: '',
    // 미션 전용 필드
    targetValue: 1,
    rewardPoints: 0,
    missionType: 'PROGRESSIVE' as 'ONE_TIME' | 'DAILY' | 'WEEKLY' | 'PROGRESSIVE',
    autoClaim: false,
    trigger: 'ALERT_CREATED' as 'FIRST_TRACKING_CREATED' | 'ALERT_CREATED' | 'TRACKING_CREATED' | 'PROFILE_UPDATED',
    progressIncrement: 1,
  });

  const handleCreate = async () => {
    if (!formData.key || !formData.startAt || !formData.endAt || !formData.contentTitle) {
      toast.error('필수 항목을 모두 입력하세요.');
      return;
    }

    if (new Date(formData.startAt) >= new Date(formData.endAt)) {
      toast.error('종료일은 시작일보다 이후여야 합니다.');
      return;
    }

    const content: any = {
      title: formData.contentTitle,
      description: formData.contentDescription,
    };
    
    // 이미지 URL이 있으면 추가
    if (formData.contentImageUrl) {
      content.image_url = formData.contentImageUrl;
    }
    
    // CTA 버튼 정보가 있으면 추가
    if (formData.ctaText) {
      content.cta = {
        text: formData.ctaText,
        deeplink: formData.ctaDeeplink || '',
      };
    }
    
    // 미션인 경우 추가 필드
    if (formData.kind === 'MISSION') {
      content.target_value = formData.targetValue;
      content.reward_points = formData.rewardPoints;
      content.mission_type = formData.missionType;
      content.auto_claim = formData.autoClaim;
    }
    
    // 백엔드는 snake_case를 기대하므로 변환
    const campaignData: any = {
      key: formData.key,
      kind: formData.kind,
      placement: formData.placement,
      template: formData.template,
      priority: formData.priority,
      is_enabled: formData.isEnabled, // snake_case로 변환
      start_at: new Date(formData.startAt).toISOString(), // snake_case로 변환
      end_at: new Date(formData.endAt).toISOString(), // snake_case로 변환
      content,
    };
    
    // 미션인 경우 actions 추가
    if (formData.kind === 'MISSION') {
      campaignData.actions = [{
        trigger: formData.trigger,
        action_type: 'UPDATE_PROGRESS',
        action: {
          progress_increment: formData.progressIncrement,
          auto_claim: formData.autoClaim,
        },
      }];
    }
    
    // rules 기본값 추가
    campaignData.rules = [];
    
    try {
      // 백엔드 API 직접 호출
      const newCampaign = await campaignService.createCampaign(campaignData);
      onCreate(newCampaign);
      toast.success('캠페인이 생성되었습니다.');
    } catch (err) {
      const errorMessage = err instanceof ApiError 
        ? `생성 실패: ${err.status} ${err.statusText}`
        : '캠페인 생성에 실패했습니다.';
      toast.error(errorMessage);
      console.error('캠페인 생성 실패:', err);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
          <h2 className="text-xl font-bold text-gray-900">새 캠페인 생성</h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-gray-600" />
          </button>
        </div>

        {/* Content */}
        <div className="px-6 py-6 overflow-y-auto max-h-[calc(90vh-180px)] space-y-4">
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">
              Campaign Key *
            </label>
            <input
              type="text"
              value={formData.key}
              onChange={(e) => setFormData({ ...formData, key: e.target.value })}
              className="admin-input w-full focus:outline-none focus:ring-2 focus:ring-blue-500 font-mono"
              placeholder="spring_event_2026"
            />
            <p className="text-xs text-gray-500 mt-1">영문, 숫자, 언더스코어만 사용 가능</p>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Kind *
              </label>
              <select
                value={formData.kind}
                onChange={(e) => setFormData({ ...formData, kind: e.target.value as any })}
                className="admin-input w-full focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="EVENT">EVENT</option>
                <option value="NOTICE">NOTICE</option>
                <option value="AD">AD</option>
                <option value="MISSION">MISSION</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Placement *
              </label>
              <select
                value={formData.placement}
                onChange={(e) => setFormData({ ...formData, placement: e.target.value as any })}
                className="admin-input w-full focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="HOME_MODAL">HOME_MODAL</option>
                <option value="HOME_BANNER">HOME_BANNER</option>
                <option value="NOTICE_CENTER">NOTICE_CENTER</option>
                <option value="BENEFITS_PAGE">BENEFITS_PAGE</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Template
              </label>
              <select
                value={formData.template}
                onChange={(e) => setFormData({ ...formData, template: e.target.value as any })}
                className="admin-input w-full focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="image_top">image_top</option>
                <option value="no_image">no_image</option>
                <option value="product_spotlight">product_spotlight</option>
                <option value="mission_card">mission_card</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Priority
              </label>
              <input
                type="number"
                value={formData.priority}
                onChange={(e) => setFormData({ ...formData, priority: parseInt(e.target.value) || 0 })}
                className="admin-input w-full focus:outline-none focus:ring-2 focus:ring-blue-500"
                min="0"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                시작일 *
              </label>
              <input
                type="datetime-local"
                value={formData.startAt}
                onChange={(e) => setFormData({ ...formData, startAt: e.target.value })}
                className="admin-input w-full focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                종료일 *
              </label>
              <input
                type="datetime-local"
                value={formData.endAt}
                onChange={(e) => setFormData({ ...formData, endAt: e.target.value })}
                className="admin-input w-full focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          <div>
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={formData.isEnabled}
                onChange={(e) => setFormData({ ...formData, isEnabled: e.target.checked })}
                className="w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
              />
              <span className="text-sm font-semibold text-gray-700">생성 즉시 활성화</span>
            </label>
          </div>

          <div className="border-t border-gray-200 pt-4">
            <h3 className="text-sm font-semibold text-gray-900 mb-3">컨텐츠 정보</h3>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  제목
                </label>
                <input
                  type="text"
                  value={formData.contentTitle}
                  onChange={(e) => setFormData({ ...formData, contentTitle: e.target.value })}
                  className="admin-input w-full focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="캠페인 제목"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  설명
                </label>
                <textarea
                  value={formData.contentDescription}
                  onChange={(e) => setFormData({ ...formData, contentDescription: e.target.value })}
                  className="admin-input w-full h-24 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="캠페인 설명"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  이미지 URL
                </label>
                <input
                  type="url"
                  value={formData.contentImageUrl}
                  onChange={(e) => setFormData({ ...formData, contentImageUrl: e.target.value })}
                  className="admin-input w-full focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="https://example.com/image.jpg"
                />
                <p className="text-xs text-gray-500 mt-1">모달 상단에 표시될 이미지 URL (선택사항)</p>
              </div>

              <div className="border-t border-gray-200 pt-4">
                <h4 className="text-sm font-semibold text-gray-900 mb-3">CTA 버튼 설정 (선택사항)</h4>
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-2">
                      버튼 텍스트
                    </label>
                    <input
                      type="text"
                      value={formData.ctaText}
                      onChange={(e) => setFormData({ ...formData, ctaText: e.target.value })}
                      className="admin-input w-full focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="예: 시작하기, 참여하기"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-2">
                      딥링크 경로
                    </label>
                    <input
                      type="text"
                      value={formData.ctaDeeplink}
                      onChange={(e) => setFormData({ ...formData, ctaDeeplink: e.target.value })}
                      className="admin-input w-full focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="예: /benefits, /home"
                    />
                    <p className="text-xs text-gray-500 mt-1">버튼 클릭 시 이동할 화면 경로</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          {/* 미션 전용 필드 */}
          {formData.kind === 'MISSION' && (
            <div className="border-t border-gray-200 pt-4">
              <h3 className="text-sm font-semibold text-gray-900 mb-3">미션 설정</h3>
              
              <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-2">
                      목표 값 *
                    </label>
                    <input
                      type="number"
                      value={formData.targetValue}
                      onChange={(e) => setFormData({ ...formData, targetValue: parseInt(e.target.value) || 1 })}
                      className="admin-input w-full focus:outline-none focus:ring-2 focus:ring-blue-500"
                      min="1"
                    />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-2">
                      보상 포인트 *
                    </label>
                    <input
                      type="number"
                      value={formData.rewardPoints}
                      onChange={(e) => setFormData({ ...formData, rewardPoints: parseInt(e.target.value) || 0 })}
                      className="admin-input w-full focus:outline-none focus:ring-2 focus:ring-blue-500"
                      min="0"
                    />
                  </div>
                </div>
                
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-2">
                      미션 타입
                    </label>
                    <select
                      value={formData.missionType}
                      onChange={(e) => setFormData({ ...formData, missionType: e.target.value as any })}
                      className="admin-input w-full focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="ONE_TIME">ONE_TIME</option>
                      <option value="DAILY">DAILY</option>
                      <option value="WEEKLY">WEEKLY</option>
                      <option value="PROGRESSIVE">PROGRESSIVE</option>
                    </select>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-2">
                      트리거
                    </label>
                    <select
                      value={formData.trigger}
                      onChange={(e) => setFormData({ ...formData, trigger: e.target.value as any })}
                      className="admin-input w-full focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="FIRST_TRACKING_CREATED">FIRST_TRACKING_CREATED</option>
                      <option value="TRACKING_CREATED">TRACKING_CREATED</option>
                      <option value="ALERT_CREATED">ALERT_CREATED</option>
                      <option value="PROFILE_UPDATED">PROFILE_UPDATED</option>
                    </select>
                  </div>
                </div>
                
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-2">
                      진행도 증가량
                    </label>
                    <input
                      type="number"
                      value={formData.progressIncrement}
                      onChange={(e) => setFormData({ ...formData, progressIncrement: parseInt(e.target.value) || 1 })}
                      className="admin-input w-full focus:outline-none focus:ring-2 focus:ring-blue-500"
                      min="1"
                    />
                  </div>
                  
                  <div>
                    <label className="flex items-center gap-2 cursor-pointer mt-8">
                      <input
                        type="checkbox"
                        checked={formData.autoClaim}
                        onChange={(e) => setFormData({ ...formData, autoClaim: e.target.checked })}
                        className="w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
                      />
                      <span className="text-sm font-semibold text-gray-700">완료 시 자동 지급</span>
                    </label>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-end gap-2 px-6 py-4 border-t border-gray-200">
          <button
            onClick={onClose}
            className="admin-btn px-6 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700"
          >
            취소
          </button>
          <button
            onClick={handleCreate}
            disabled={!formData.key || !formData.startAt || !formData.endAt || !formData.contentTitle}
            className="admin-btn px-6 py-2 bg-blue-500 hover:bg-blue-600 text-white disabled:opacity-50 disabled:cursor-not-allowed"
          >
            생성
          </button>
        </div>
      </div>
    </div>
  );
}
