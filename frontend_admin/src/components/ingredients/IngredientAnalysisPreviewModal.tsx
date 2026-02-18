import { X, Save } from 'lucide-react';

interface ParsedData {
  ingredients?: Array<{ name: string; category?: string; percentage?: number }>;
  additives?: Array<{ name: string; type?: string }>;
  allergens?: Array<{ name: string; code?: string }>;
  summary?: {
    main_ingredients?: string[];
    additives_count?: number;
    allergens_count?: number;
  };
}

interface IngredientAnalysisPreviewModalProps {
  parsed: ParsedData;
  onClose: () => void;
  onSave: () => void;
  saving?: boolean;
}

export function IngredientAnalysisPreviewModal({
  parsed,
  onClose,
  onSave,
  saving = false,
}: IngredientAnalysisPreviewModalProps) {
  const mainIngredients = parsed.ingredients || parsed.summary?.main_ingredients || [];
  const additives = parsed.additives || [];
  const allergens = parsed.allergens || [];

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-hidden flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
          <h2 className="text-xl font-bold text-gray-900">AI 분석 결과 미리보기</h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
            disabled={saving}
          >
            <X className="w-5 h-5 text-gray-600" />
          </button>
        </div>

        {/* Content */}
        <div className="px-6 py-6 overflow-y-auto flex-1 space-y-6">
          {/* 주요 성분 */}
          {mainIngredients.length > 0 && (
            <div>
              <h3 className="text-sm font-semibold text-gray-700 mb-3">주요 성분</h3>
              <div className="flex flex-wrap gap-2">
                {mainIngredients.map((item, idx) => {
                  const name = typeof item === 'string' ? item : item.name;
                  const percentage = typeof item === 'object' && item.percentage ? `${item.percentage}%` : null;
                  return (
                    <div
                      key={idx}
                      className="px-3 py-1.5 bg-blue-50 text-blue-700 text-sm rounded-full flex items-center gap-2"
                    >
                      <span>{name}</span>
                      {percentage && (
                        <span className="text-xs text-blue-500">({percentage})</span>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* 첨가제 */}
          {additives.length > 0 && (
            <div>
              <h3 className="text-sm font-semibold text-gray-700 mb-3">첨가제</h3>
              <div className="flex flex-wrap gap-2">
                {additives.map((item, idx) => {
                  const name = typeof item === 'string' ? item : item.name;
                  const type = typeof item === 'object' && item.type ? item.type : null;
                  return (
                    <div
                      key={idx}
                      className="px-3 py-1.5 bg-gray-50 text-gray-700 text-sm rounded-full flex items-center gap-2"
                    >
                      <span>{name}</span>
                      {type && (
                        <span className="text-xs text-gray-500">({type})</span>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* 알레르겐 */}
          {allergens.length > 0 && (
            <div>
              <h3 className="text-sm font-semibold text-gray-700 mb-3">알레르기 유발 성분</h3>
              <div className="flex flex-wrap gap-2">
                {allergens.map((item, idx) => {
                  const name = typeof item === 'string' ? item : item.name;
                  return (
                    <div
                      key={idx}
                      className="px-3 py-1.5 bg-red-50 text-red-700 text-sm rounded-full"
                    >
                      {name}
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* 요약 정보 */}
          {parsed.summary && (
            <div className="p-4 bg-gray-50 rounded-lg">
              <h3 className="text-sm font-semibold text-gray-700 mb-2">분석 요약</h3>
              <div className="space-y-1 text-sm text-gray-600">
                {parsed.summary.main_ingredients && (
                  <div>주요 성분: {parsed.summary.main_ingredients.length}개</div>
                )}
                {parsed.summary.additives_count !== undefined && (
                  <div>첨가제: {parsed.summary.additives_count}개</div>
                )}
                {parsed.summary.allergens_count !== undefined && (
                  <div>알레르겐: {parsed.summary.allergens_count}개</div>
                )}
              </div>
            </div>
          )}

          {/* Raw JSON (개발용) */}
          <details className="mt-4">
            <summary className="text-xs text-gray-500 cursor-pointer hover:text-gray-700">
              원본 JSON 보기
            </summary>
            <pre className="mt-2 p-3 bg-gray-100 rounded text-xs overflow-x-auto">
              {JSON.stringify(parsed, null, 2)}
            </pre>
          </details>
        </div>

        {/* Footer */}
        <div className="flex items-center justify-end gap-2 px-6 py-4 border-t border-gray-200">
          <button
            onClick={onClose}
            disabled={saving}
            className="admin-btn px-6 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 disabled:opacity-50"
          >
            취소
          </button>
          <button
            onClick={onSave}
            disabled={saving}
            className="admin-btn px-6 py-2 bg-blue-500 hover:bg-blue-600 text-white disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
          >
            <Save className="w-4 h-4" />
            {saving ? '저장 중...' : '저장'}
          </button>
        </div>
      </div>
    </div>
  );
}
