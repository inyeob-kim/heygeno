import { useState, useEffect } from 'react';
import { Plus, Search } from 'lucide-react';
import { Campaign } from '../../data/mockCampaigns';
import { CampaignDetailSheet } from './CampaignDetailSheet';
import { CreateCampaignDialog } from './CreateCampaignDialog';
import { campaignService } from '../../services/campaignService';
import { toast } from 'sonner@2.0.3';
import { ApiError } from '../../config/api';

export function CampaignList() {
  const [campaigns, setCampaigns] = useState<Campaign[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedCampaign, setSelectedCampaign] = useState<Campaign | null>(null);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [typeFilter, setTypeFilter] = useState<string>('ALL');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');

  // 캠페인 목록 로드
  useEffect(() => {
    loadCampaigns();
  }, []);

  const loadCampaigns = async () => {
    try {
      setLoading(true);
      setError(null);
      const params: any = {};
      if (typeFilter !== 'ALL') params.kind = typeFilter;
      if (statusFilter !== 'ALL') {
        params.enabled = statusFilter === 'ACTIVE_NOW' || statusFilter === 'SCHEDULED';
      }
      const data = await campaignService.getCampaigns(params);
      setCampaigns(data);
    } catch (err) {
      const errorMessage = err instanceof ApiError 
        ? `API 오류: ${err.status} ${err.statusText}`
        : err instanceof Error 
        ? err.message 
        : '캠페인 목록을 불러오는데 실패했습니다.';
      setError(errorMessage);
      toast.error(errorMessage);
      console.error('캠페인 목록 로드 실패:', err);
    } finally {
      setLoading(false);
    }
  };

  const filteredCampaigns = campaigns.filter((campaign) => {
    const matchesSearch =
      searchQuery === '' ||
      campaign.key.toLowerCase().includes(searchQuery.toLowerCase()) ||
      campaign.content.title?.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesType = typeFilter === 'ALL' || campaign.kind === typeFilter;
    const matchesStatus = statusFilter === 'ALL' || campaign.status === statusFilter;
    return matchesSearch && matchesType && matchesStatus;
  });

  const handleToggleEnabled = async (campaignId: string) => {
    try {
      const campaign = campaigns.find(c => c.id === campaignId);
      if (!campaign) return;
      
      const updated = await campaignService.toggleCampaign(campaignId, !campaign.isEnabled);
      setCampaigns((prev) =>
        prev.map((c) => (c.id === campaignId ? updated : c))
      );
      toast.success('캠페인 활성화 상태를 변경했습니다.');
    } catch (err) {
      const errorMessage = err instanceof ApiError 
        ? `상태 변경 실패: ${err.status} ${err.statusText}`
        : '캠페인 상태 변경에 실패했습니다.';
      toast.error(errorMessage);
      console.error('캠페인 상태 변경 실패:', err);
    }
  };

  const handleCreate = async (newCampaign: Campaign) => {
    // CreateCampaignDialog에서 이미 생성 완료된 캠페인을 받음
    setCampaigns(prev => [newCampaign, ...prev]);
    setShowCreateDialog(false);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">로딩 중...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="admin-card p-6">
        <div className="text-red-600 mb-4">{error}</div>
        <button
          onClick={loadCampaigns}
          className="admin-btn px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white"
        >
          다시 시도
        </button>
      </div>
    );
  }

  return (
    <>
      <div className="admin-card p-6">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-bold text-gray-900">캠페인 목록</h2>
          <button
            onClick={() => setShowCreateDialog(true)}
            className="admin-btn px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white flex items-center gap-2"
          >
            <Plus className="w-4 h-4" />
            새 캠페인
          </button>
        </div>

        {/* Filters */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-3 mb-6">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="Key / Title 검색"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="admin-input w-full pl-10 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <select
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value)}
            className="admin-input focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="ALL">전체 타입</option>
            <option value="EVENT">EVENT</option>
            <option value="NOTICE">NOTICE</option>
            <option value="AD">AD</option>
            <option value="MISSION">MISSION</option>
          </select>

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="admin-input focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="ALL">전체 상태</option>
            <option value="ACTIVE_NOW">진행중</option>
            <option value="SCHEDULED">예정</option>
            <option value="EXPIRED">종료</option>
            <option value="DISABLED">비활성</option>
          </select>
        </div>

        {/* Table */}
        <div className="border border-gray-200 rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-600">우선순위</th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-600">Key</th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-600">타입</th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-600">배치</th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-600">템플릿</th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-600">기간</th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-600">상태</th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-600">활성화</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredCampaigns.map((campaign) => (
                  <tr
                    key={campaign.id}
                    className="hover:bg-gray-50 cursor-pointer transition-colors"
                    onClick={() => setSelectedCampaign(campaign)}
                  >
                    <td className="px-4 py-3">
                      <span className="font-semibold text-gray-900">{campaign.priority}</span>
                    </td>
                    <td className="px-4 py-3">
                      <code className="text-sm text-blue-600 font-mono">{campaign.key}</code>
                    </td>
                    <td className="px-4 py-3">
                      <span
                        className={`px-2 py-1 rounded-full text-xs font-semibold ${
                          campaign.kind === 'EVENT'
                            ? 'bg-purple-100 text-purple-700'
                            : campaign.kind === 'NOTICE'
                            ? 'bg-blue-100 text-blue-700'
                            : 'bg-gray-100 text-gray-700'
                        }`}
                      >
                        {campaign.kind}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <span className="px-2 py-1 bg-cyan-100 text-cyan-700 rounded-full text-xs font-semibold">
                        {campaign.placement}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <span className="text-sm text-gray-600">{campaign.template}</span>
                    </td>
                    <td className="px-4 py-3">
                      <div className="text-sm text-gray-600">
                        <div>{new Date(campaign.startAt).toLocaleDateString('ko-KR')}</div>
                        <div className="text-xs text-gray-400">
                          ~ {new Date(campaign.endAt).toLocaleDateString('ko-KR')}
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <span
                        className={`px-2 py-1 rounded-full text-xs font-semibold ${
                          campaign.status === 'ACTIVE_NOW'
                            ? 'bg-green-100 text-green-700'
                            : campaign.status === 'SCHEDULED'
                            ? 'bg-yellow-100 text-yellow-700'
                            : campaign.status === 'EXPIRED'
                            ? 'bg-gray-100 text-gray-700'
                            : 'bg-red-100 text-red-700'
                        }`}
                      >
                        {campaign.status === 'ACTIVE_NOW'
                          ? '진행중'
                          : campaign.status === 'SCHEDULED'
                          ? '예정'
                          : campaign.status === 'EXPIRED'
                          ? '종료'
                          : '비활성'}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          handleToggleEnabled(campaign.id);
                        }}
                        className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                          campaign.isEnabled ? 'bg-blue-500' : 'bg-gray-300'
                        }`}
                      >
                        <span
                          className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                            campaign.isEnabled ? 'translate-x-6' : 'translate-x-1'
                          }`}
                        />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Pagination */}
        <div className="flex items-center justify-between mt-4 text-sm text-gray-600">
          <span>총 {filteredCampaigns.length}개 캠페인</span>
        </div>
      </div>

      {/* Campaign Detail Sheet */}
      {selectedCampaign && (
        <CampaignDetailSheet
          campaign={selectedCampaign}
          onClose={() => setSelectedCampaign(null)}
          onUpdate={(updated) => {
            setCampaigns((prev) =>
              prev.map((c) => (c.id === updated.id ? updated : c))
            );
            toast.success('캠페인이 업데이트되었습니다.');
          }}
          onDelete={(id) => {
            setCampaigns(prev => prev.filter(c => c.id !== id));
            setSelectedCampaign(null);
            toast.success('캠페인이 삭제되었습니다.');
          }}
        />
      )}

      {/* Create Campaign Dialog */}
      {showCreateDialog && (
        <CreateCampaignDialog
          onClose={() => setShowCreateDialog(false)}
          onCreate={handleCreate}
        />
      )}
    </>
  );
}