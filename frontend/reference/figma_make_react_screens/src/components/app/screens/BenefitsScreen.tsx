import { useState, useEffect } from 'react';
import { AppBar } from '../components/AppBar';
import { PrimaryButton } from '../components/PrimaryButton';
import { Gift, CheckCircle, Target } from 'lucide-react';

const API_BASE_URL = 'http://localhost:8000/api/v1';

interface Mission {
  id: string;
  campaign_id: string;
  title: string;
  description: string;
  reward_points: number;
  current_value: number;
  target_value: number;
  status: string;
  completed: boolean;
  can_claim: boolean;
}

export function BenefitsScreen() {
  const [missions, setMissions] = useState<Mission[]>([]);
  const [totalPoints, setTotalPoints] = useState(0);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadMissions();
    loadPoints();
  }, []);

  const loadMissions = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/missions`, {
        headers: { 
          'X-Device-UID': 'your-device-uid', // TODO: 실제 device_uid 사용
          'Content-Type': 'application/json'
        }
      });
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const data = await response.json();
      setMissions(data);
    } catch (error) {
      console.error('미션 로드 실패:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadPoints = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/points/balance`, {
        headers: { 
          'X-Device-UID': 'your-device-uid', // TODO: 실제 device_uid 사용
          'Content-Type': 'application/json'
        }
      });
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const data = await response.json();
      setTotalPoints(data.balance);
    } catch (error) {
      console.error('포인트 로드 실패:', error);
    }
  };

  const handleClaimReward = async (campaignId: string) => {
    try {
      const response = await fetch(`${API_BASE_URL}/missions/${campaignId}/claim`, {
        method: 'POST',
        headers: { 
          'X-Device-UID': 'your-device-uid', // TODO: 실제 device_uid 사용
          'Content-Type': 'application/json'
        }
      });
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      await loadMissions();
      await loadPoints();
    } catch (error) {
      console.error('보상 받기 실패:', error);
    }
  };

  if (loading) {
    return (
      <div className="pb-6">
        <AppBar title="혜택" />
        <div className="flex items-center justify-center h-64">
          <p className="text-body text-[#6B7280]">로딩 중...</p>
        </div>
      </div>
    );
  }

  // 하드코딩된 미션 목록 (폴백용 - API 실패 시)
  const fallbackMissions: any[] = [
    { 
      id: '1', 
      campaign_id: '1',
      title: '오늘 추천 사료 찜하기', 
      description: '홈에서 추천된 사료를 찜 목록에 추가하세요',
      reward: 50, 
      reward_points: 50,
      completed: true, 
      current: 1,
      current_value: 1,
      total: 1,
      target_value: 1,
      can_claim: false
    },
    { 
      id: '2', 
      campaign_id: '2',
      title: '가격 알림 3개 설정', 
      description: '관심 사료의 가격 변동을 실시간으로 확인하세요',
      reward: 100,
      reward_points: 100,
      completed: true, 
      current: 3,
      current_value: 3,
      total: 3,
      target_value: 3,
      can_claim: false
    },
    { 
      id: '3', 
      campaign_id: '3',
      title: '펫 프로필 업데이트', 
      description: '정확한 체중과 건강 정보를 입력해주세요',
      reward: 30,
      reward_points: 30,
      completed: false, 
      current: 0,
      current_value: 0,
      total: 1,
      target_value: 1,
      can_claim: false
    },
    { 
      id: '4', 
      campaign_id: '4',
      title: '추천 제품 구매', 
      description: '맞춤 추천 제품을 구매하고 포인트를 받으세요',
      reward: 200,
      reward_points: 200,
      completed: false, 
      current: 0,
      current_value: 0,
      total: 1,
      target_value: 1,
      can_claim: false
    },
    { 
      id: '5', 
      campaign_id: '5',
      title: '리뷰 작성하기', 
      description: '구매한 제품의 리뷰를 남겨주세요',
      reward: 150,
      reward_points: 150,
      completed: false, 
      current: 0,
      current_value: 0,
      total: 1,
      target_value: 1,
      can_claim: false
    },
  ];
    { 
      id: 1, 
      title: '오늘 추천 사료 찜하기', 
      description: '홈에서 추천된 사료를 찜 목록에 추가하세요',
      reward: 50, 
      completed: true, 
      current: 1, 
      total: 1 
    },
    { 
      id: 2, 
      title: '가격 알림 3개 설정', 
      description: '관심 사료의 가격 변동을 실시간으로 확인하세요',
      reward: 100, 
      completed: true, 
      current: 3, 
      total: 3 
    },
    { 
      id: 3, 
      title: '펫 프로필 업데이트', 
      description: '정확한 체중과 건강 정보를 입력해주세요',
      reward: 30, 
      completed: false, 
      current: 0, 
      total: 1 
    },
    { 
      id: 4, 
      title: '추천 제품 구매', 
      description: '맞춤 추천 제품을 구매하고 포인트를 받으세요',
      reward: 200, 
      completed: false, 
      current: 0, 
      total: 1 
    },
    { 
      id: 5, 
      title: '리뷰 작성하기', 
      description: '구매한 제품의 리뷰를 남겨주세요',
      reward: 150, 
      completed: false, 
      current: 0, 
      total: 1 
    },
  ];

  const earnedPoints = missions.filter(m => m.completed).reduce((sum, m) => sum + m.reward_points, 0);
  const availablePoints = missions.filter(m => !m.completed).reduce((sum, m) => sum + m.reward_points, 0);

  return (
    <div className="pb-6">
      <AppBar title="혜택" />
      
      <div className="px-4 space-y-8">
        {/* Hero Point Section */}
        <div className="pt-6">
          <div className="flex items-center gap-2 mb-2">
            <Gift className="w-6 h-6 text-[#2563EB]" />
            <p className="text-body text-[#6B7280]">내 포인트</p>
          </div>
          <div className="text-hero text-[#2563EB] mb-3">{totalPoints.toLocaleString()}P</div>
          <p className="text-body text-[#6B7280]">
            {availablePoints.toLocaleString()}P 더 받을 수 있어요
          </p>
        </div>

        {/* Mission List - Service Connected */}
        <div>
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-body text-[#111827]">미션 완료하고 포인트 받기</h3>
            <span className="text-sub text-[#6B7280]">
              {(missions.length > 0 ? missions : fallbackMissions).filter(m => m.completed).length}/{(missions.length > 0 ? missions : fallbackMissions).length}
            </span>
          </div>
          
          <div className="space-y-3">
            {(missions.length > 0 ? missions : fallbackMissions).map((mission) => (
              <div
                key={mission.id}
                className={`p-4 rounded-2xl transition-all ${
                  mission.completed 
                    ? 'bg-[#F0FDF4] border border-[#16A34A]/20' 
                    : 'bg-[#F7F8FA]'
                }`}
              >
                <div className="flex items-start gap-3 mb-3">
                  <div className={`w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0 ${
                    mission.completed ? 'bg-[#16A34A]' : 'bg-white'
                  }`}>
                    {mission.completed ? (
                      <CheckCircle className="w-6 h-6 text-white" />
                    ) : (
                      <Target className="w-6 h-6 text-[#6B7280]" />
                    )}
                  </div>
                  <div className="flex-1">
                    <h4 className={`text-body mb-1 ${
                      mission.completed ? 'text-[#6B7280]' : 'text-[#111827]'
                    }`}>
                      {mission.title || (mission as any).title}
                    </h4>
                    <p className="text-sub text-[#6B7280] mb-2">
                      {mission.description || (mission as any).description}
                    </p>
                    <div className="flex items-center gap-2">
                      <div className={`text-body font-semibold ${
                        mission.completed ? 'text-[#16A34A]' : 'text-[#2563EB]'
                      }`}>
                        +{mission.reward_points || (mission as any).reward}P
                      </div>
                      {!mission.completed && (
                        <span className="text-sub text-[#6B7280]">
                          · {mission.current_value || (mission as any).current}/{mission.target_value || (mission as any).total} 완료
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                {mission.can_claim && (
                  <PrimaryButton 
                    variant="small" 
                    onClick={() => {
                      handleClaimReward(mission.campaign_id || mission.id);
                    }}
                  >
                    보상 받기
                  </PrimaryButton>
                )}
                {!mission.completed && !mission.can_claim && (
                  <PrimaryButton variant="small" onClick={() => {}}>
                    시작하기
                  </PrimaryButton>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Points Usage */}
        <div className="p-4 rounded-2xl bg-[#EFF6FF]">
          <h3 className="text-body text-[#111827] mb-2">포인트 사용 방법</h3>
          <p className="text-sub text-[#6B7280]">
            100P = 100원 할인 (다음 구매 시 자동 적용)
          </p>
        </div>
      </div>
    </div>
  );
}
