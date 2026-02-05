import { AppBar } from '../components/AppBar';
import { PrimaryButton } from '../components/PrimaryButton';
import { Gift, CheckCircle, Target } from 'lucide-react';

export function BenefitsScreen() {
  const missions = [
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

  const totalPoints = 1850;
  const earnedPoints = missions.filter(m => m.completed).reduce((sum, m) => sum + m.reward, 0);
  const availablePoints = missions.filter(m => !m.completed).reduce((sum, m) => sum + m.reward, 0);

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
            <span className="text-sub text-[#6B7280]">{missions.filter(m => m.completed).length}/{missions.length}</span>
          </div>
          
          <div className="space-y-3">
            {missions.map((mission) => (
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
                      {mission.title}
                    </h4>
                    <p className="text-sub text-[#6B7280] mb-2">
                      {mission.description}
                    </p>
                    <div className="flex items-center gap-2">
                      <div className={`text-body font-semibold ${
                        mission.completed ? 'text-[#16A34A]' : 'text-[#2563EB]'
                      }`}>
                        +{mission.reward}P
                      </div>
                      {!mission.completed && (
                        <span className="text-sub text-[#6B7280]">
                          · {mission.current}/{mission.total} 완료
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                {!mission.completed && (
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
