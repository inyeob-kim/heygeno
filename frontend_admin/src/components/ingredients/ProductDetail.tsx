import { useState, useEffect } from 'react';
import { Copy, Pencil, Trash2, ChevronDown, Sparkles, Plus } from 'lucide-react';
import { Product } from '../../data/mockProducts';
import { toast } from 'sonner@2.0.3';
import { EditProductDialog } from './EditProductDialog';
import { EditIngredientDialog } from './EditIngredientDialog';
import { EditNutritionDialog } from './EditNutritionDialog';
import { AddAllergenDialog } from './AddAllergenDialog';
import { AddClaimDialog } from './AddClaimDialog';
import { AddOfferDialog } from './AddOfferDialog';
import { IngredientAnalysisPreviewModal } from './IngredientAnalysisPreviewModal';
import { productService } from '../../services/productService';
import { ApiError } from '../../config/api';

interface ProductDetailProps {
  product: Product | null;
  onUpdate: (product: Product) => void;
  onDelete: (productId: string) => void;
}

export function ProductDetail({ product, onUpdate, onDelete }: ProductDetailProps) {
  const [openSection, setOpenSection] = useState<string>('basic');
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [showEditIngredient, setShowEditIngredient] = useState(false);
  const [showEditNutrition, setShowEditNutrition] = useState(false);
  const [showAddAllergen, setShowAddAllergen] = useState(false);
  const [showAddClaim, setShowAddClaim] = useState(false);
  const [showAddOffer, setShowAddOffer] = useState(false);
  const [showEditOffer, setShowEditOffer] = useState(false);
  const [editingOffer, setEditingOffer] = useState<any>(null);
  const [showAnalysisPreview, setShowAnalysisPreview] = useState(false);
  const [analysisResult, setAnalysisResult] = useState<any>(null);
  
  // 상세 정보 상태
  const [ingredients, setIngredients] = useState<string[]>([]);
  const [ingredientProfile, setIngredientProfile] = useState<any>(null); // 성분 프로필 전체 데이터
  const [nutrition, setNutrition] = useState<Record<string, any>>({});
  const [allergens, setAllergens] = useState<any[]>([]);
  const [claims, setClaims] = useState<any[]>([]);
  const [offers, setOffers] = useState<any[]>([]);
  const [images, setImages] = useState<string[]>([]);
  const [loading, setLoading] = useState<Record<string, boolean>>({});
  
  // 상품이 변경될 때마다 상세 정보 로드
  useEffect(() => {
    if (product) {
      loadProductDetails();
    }
  }, [product?.id]);

  const loadProductDetails = async () => {
    if (!product) return;
    
    try {
      // 성분 정보
      try {
        const ingredientData = await productService.getIngredient(product.id);
        if (ingredientData) {
          setIngredientProfile(ingredientData);
          // parsed 데이터에서 ingredients 배열 추출
          if (ingredientData.parsed?.ingredients) {
            setIngredients(Array.isArray(ingredientData.parsed.ingredients) ? ingredientData.parsed.ingredients : []);
          } else if (ingredientData.ingredients_text) {
            // parsed가 없으면 ingredients_text를 쉼표로 분리
            const ingredientList = ingredientData.ingredients_text.split(',').map((s: string) => s.trim()).filter(Boolean);
            setIngredients(ingredientList);
          } else {
            setIngredients([]);
          }
        } else {
          setIngredientProfile(null);
          setIngredients([]);
        }
      } catch (err) {
        console.log('성분 정보 없음');
        setIngredientProfile(null);
        setIngredients([]);
      }

      // 영양 정보
      try {
        const nutritionData = await productService.getNutrition(product.id);
        if (nutritionData) {
          setNutrition(nutritionData);
        } else {
          setNutrition({});
        }
      } catch (err) {
        console.log('영양 정보 없음');
        setNutrition({});
      }

      // 알레르겐
      try {
        const allergensData = await productService.getProductAllergens(product.id);
        setAllergens(Array.isArray(allergensData) ? allergensData : []);
      } catch (err) {
        console.log('알레르겐 정보 없음');
      }

      // 클레임
      try {
        const claimsData = await productService.getProductClaims(product.id);
        setClaims(Array.isArray(claimsData) ? claimsData : []);
      } catch (err) {
        console.log('클레임 정보 없음');
      }

      // 판매처
      try {
        const offersData = await productService.getOffers(product.id);
        setOffers(Array.isArray(offersData) ? offersData : []);
      } catch (err) {
        console.log('판매처 정보 없음');
      }

      // 이미지
      try {
        const imagesData = await productService.getImages(product.id);
        setImages(Array.isArray(imagesData) ? imagesData : []);
      } catch (err) {
        console.log('이미지 정보 없음');
      }
    } catch (err) {
      console.error('상세 정보 로드 실패:', err);
    }
  };

  if (!product) {
    return (
      <div className="admin-card p-12 flex flex-col items-center justify-center text-center">
        <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mb-4">
          <span className="text-2xl">📦</span>
        </div>
        <h3 className="text-lg font-semibold text-gray-900 mb-2">상품을 선택하세요</h3>
        <p className="text-sm text-gray-500">
          왼쪽 목록에서 상품을 선택하면 상세 정보가 표시됩니다.
        </p>
      </div>
    );
  }

  const handleCopy = (text: string) => {
    navigator.clipboard.writeText(text);
    toast.success('클립보드에 복사되었습니다.');
  };

  const handleToggleStatus = async () => {
    if (!product) return;
    
    try {
      if (product.status === 'ACTIVE') {
        await productService.archiveProduct(product.id);
        onUpdate({ ...product, status: 'ARCHIVED' });
        toast.success('상품을 비활성화했습니다.');
      } else {
        await productService.unarchiveProduct(product.id);
        onUpdate({ ...product, status: 'ACTIVE' });
        toast.success('상품을 활성화했습니다.');
      }
    } catch (err) {
      const errorMessage = err instanceof ApiError 
        ? `상태 변경 실패: ${err.status} ${err.statusText}`
        : '상태 변경에 실패했습니다.';
      toast.error(errorMessage);
    }
  };

  const handleAnalyzeIngredients = async () => {
    if (!product || !ingredientProfile) return;
    
    // 성분 텍스트가 없으면 에러
    if (!ingredientProfile.ingredients_text || !ingredientProfile.ingredients_text.trim()) {
      toast.error('먼저 성분 정보를 입력해주세요.');
      return;
    }
    
    try {
      setLoading(prev => ({ ...prev, analyze: true }));
      
      // AI 분석만 수행 (저장하지 않음)
      const result = await productService.analyzeIngredients({
        ingredients_text: ingredientProfile.ingredients_text,
        additives_text: ingredientProfile.additives_text || '',
        species: product.species,
      });
      
      // 분석 결과를 상태에 저장하고 미리보기 모달 표시
      setAnalysisResult(result.parsed);
      setShowAnalysisPreview(true);
    } catch (err) {
      const errorMessage = err instanceof ApiError 
        ? `분석 실패: ${err.status} ${err.statusText}`
        : '성분 분석에 실패했습니다.';
      toast.error(errorMessage);
    } finally {
      setLoading(prev => ({ ...prev, analyze: false }));
    }
  };

  const handleSaveAnalysis = async () => {
    if (!product || !analysisResult) return;
    
    try {
      setLoading(prev => ({ ...prev, saveParsed: true }));
      
      // 분석된 parsed 데이터 저장
      await productService.saveParsed(product.id, analysisResult);
      
      // 상세 정보 다시 로드
      await loadProductDetails();
      
      toast.success('성분 분석 결과가 저장되었습니다.');
      setShowAnalysisPreview(false);
      setAnalysisResult(null);
    } catch (err) {
      const errorMessage = err instanceof ApiError 
        ? `저장 실패: ${err.status} ${err.statusText}`
        : '분석 결과 저장에 실패했습니다.';
      toast.error(errorMessage);
    } finally {
      setLoading(prev => ({ ...prev, saveParsed: false }));
    }
  };

  const handleDeleteAllergen = async (allergenCode: string) => {
    if (!product) return;
    
    try {
      await productService.deleteAllergen(product.id, allergenCode);
      setAllergens(prev => prev.filter(a => a.code !== allergenCode && a.allergen_code !== allergenCode));
      toast.success('알레르겐이 삭제되었습니다.');
    } catch (err) {
      const errorMessage = err instanceof ApiError 
        ? `삭제 실패: ${err.status} ${err.statusText}`
        : '알레르겐 삭제에 실패했습니다.';
      toast.error(errorMessage);
    }
  };

  const handleDeleteClaim = async (claimCode: string) => {
    if (!product) return;
    
    try {
      await productService.deleteClaim(product.id, claimCode);
      setClaims(prev => prev.filter(c => c.code !== claimCode && c.claim_code !== claimCode));
      toast.success('클레임이 삭제되었습니다.');
    } catch (err) {
      const errorMessage = err instanceof ApiError 
        ? `삭제 실패: ${err.status} ${err.statusText}`
        : '클레임 삭제에 실패했습니다.';
      toast.error(errorMessage);
    }
  };

  const handleDelete = () => {
    onDelete(product.id);
    setShowDeleteConfirm(false);
    toast.success('상품이 삭제되었습니다.');
  };

  const toggleSection = (section: string) => {
    setOpenSection(openSection === section ? '' : section);
  };

  const merchantToPlatform = (merchant?: string) => {
    if (merchant === 'COUPANG') return '쿠팡';
    if (merchant === 'NAVER') return '네이버쇼핑';
    if (merchant === 'BRAND') return '기타';
    return '기타';
  };

  return (
    <>
      <div className="space-y-4">
        {/* Summary Card */}
        <div className="admin-card p-6">
          <div className="flex gap-6">
            <img
              src={product.thumbnail}
              alt={product.name}
              className="w-24 h-24 rounded-xl object-cover"
            />
            <div className="flex-1">
              <div className="flex items-start justify-between mb-3">
                <div>
                  <h2 className="text-xl font-bold text-gray-900 mb-1">{product.name}</h2>
                  <p className="text-sm text-gray-600">{product.brand}</p>
                </div>
                <span
                  className={`px-3 py-1 rounded-full text-xs font-semibold ${
                    product.species === 'DOG'
                      ? 'bg-blue-100 text-blue-700'
                      : 'bg-purple-100 text-purple-700'
                  }`}
                >
                  {product.species === 'DOG' ? '강아지' : '고양이'}
                </span>
              </div>

              <div className="grid grid-cols-2 gap-3 mb-4 text-sm">
                <div className="flex items-center gap-2">
                  <span className="text-gray-500">Product ID:</span>
                  <code className="bg-gray-100 px-2 py-1 rounded text-xs font-mono">
                    {product.id}
                  </code>
                  <button onClick={() => handleCopy(product.id)} className="text-gray-400 hover:text-gray-600">
                    <Copy className="w-3 h-3" />
                  </button>
                </div>
                <div>
                  <span className="text-gray-500">생성일:</span> {new Date(product.createdAt).toLocaleDateString('ko-KR')}
                </div>
                <div>
                  <span className="text-gray-500">수정일:</span> {new Date(product.updatedAt).toLocaleDateString('ko-KR')}
                </div>
                <div>
                  <span className="text-gray-500">상태:</span>{' '}
                  <span
                    className={`font-semibold ${
                      product.status === 'ACTIVE' ? 'text-green-600' : 'text-gray-600'
                    }`}
                  >
                    {product.status === 'ACTIVE' ? '활성' : '비활성'}
                  </span>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <button
                  onClick={() => setShowEditDialog(true)}
                  className="admin-btn px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white text-sm flex items-center gap-2"
                >
                  <Pencil className="w-4 h-4" />
                  수정
                </button>
                <button
                  onClick={handleToggleStatus}
                  className="admin-btn px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 text-sm"
                >
                  {product.status === 'ACTIVE' ? '비활성화' : '활성화'}
                </button>
                <button
                  onClick={() => setShowDeleteConfirm(true)}
                  className="admin-btn px-4 py-2 bg-red-50 hover:bg-red-100 text-red-600 text-sm flex items-center gap-2"
                >
                  <Trash2 className="w-4 h-4" />
                  삭제
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Accordion Sections */}
        <div className="space-y-3">
          {/* 성분 프로필 */}
          <div className="admin-card overflow-hidden">
            <button
              onClick={() => toggleSection('ingredients')}
              className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
            >
              <h3 className="font-bold text-gray-900">성분 프로필</h3>
              <ChevronDown
                className={`w-5 h-5 text-gray-500 transition-transform ${
                  openSection === 'ingredients' ? 'rotate-180' : ''
                }`}
              />
            </button>
            {openSection === 'ingredients' && (
              <div className="px-6 pb-6 border-t border-gray-200">
                <div className="pt-4 space-y-4">
                  <div>
                    <div className="text-sm font-semibold text-gray-700 mb-2">주요 성분</div>
                    <div className="flex flex-wrap gap-2">
                      {ingredients.length > 0 ? (
                        ingredients.map((ingredient, idx) => (
                          <span
                            key={idx}
                            className="px-3 py-1 bg-gray-100 text-gray-700 text-sm rounded-full"
                          >
                            {typeof ingredient === 'string' ? ingredient : ingredient.name || ingredient.ingredient_name}
                          </span>
                        ))
                      ) : (
                        <span className="text-sm text-gray-500">성분 정보가 없습니다.</span>
                      )}
                    </div>
                  </div>
                  <div className="flex gap-2">
                    <button
                      onClick={handleAnalyzeIngredients}
                      disabled={loading.analyze}
                      className="admin-btn px-4 py-2 bg-gradient-to-r from-blue-500 to-cyan-500 hover:from-blue-600 hover:to-cyan-600 text-white text-sm flex items-center gap-2 disabled:opacity-50"
                    >
                      <Sparkles className="w-4 h-4" />
                      {loading.analyze ? '분석 중...' : 'AI 분석 & 저장'}
                    </button>
                    <button
                      onClick={() => setShowEditIngredient(true)}
                      className="admin-btn px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 text-sm"
                    >
                      {ingredientProfile?.ingredients_text ? '수동 수정' : '성분 정보 추가'}
                    </button>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* 영양 정보 */}
          <div className="admin-card overflow-hidden">
            <button
              onClick={() => toggleSection('nutrition')}
              className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
            >
              <h3 className="font-bold text-gray-900">영양 정보</h3>
              <ChevronDown
                className={`w-5 h-5 text-gray-500 transition-transform ${
                  openSection === 'nutrition' ? 'rotate-180' : ''
                }`}
              />
            </button>
            {openSection === 'nutrition' && (
              <div className="px-6 pb-6 border-t border-gray-200">
                <div className="pt-4 space-y-4">
                  {nutrition && (nutrition.protein_pct || nutrition.fat_pct || nutrition.fiber_pct || nutrition.moisture_pct || nutrition.kcal_per_100g) ? (
                    <div className="grid grid-cols-2 gap-4">
                      {nutrition.protein_pct && (
                        <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                          <span className="text-sm font-medium text-gray-700">단백질</span>
                          <span className="text-sm font-bold text-gray-900">{nutrition.protein_pct}%</span>
                        </div>
                      )}
                      {nutrition.fat_pct && (
                        <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                          <span className="text-sm font-medium text-gray-700">지방</span>
                          <span className="text-sm font-bold text-gray-900">{nutrition.fat_pct}%</span>
                        </div>
                      )}
                      {nutrition.fiber_pct && (
                        <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                          <span className="text-sm font-medium text-gray-700">섬유질</span>
                          <span className="text-sm font-bold text-gray-900">{nutrition.fiber_pct}%</span>
                        </div>
                      )}
                      {nutrition.moisture_pct && (
                        <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                          <span className="text-sm font-medium text-gray-700">수분</span>
                          <span className="text-sm font-bold text-gray-900">{nutrition.moisture_pct}%</span>
                        </div>
                      )}
                      {nutrition.ash_pct && (
                        <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                          <span className="text-sm font-medium text-gray-700">회분</span>
                          <span className="text-sm font-bold text-gray-900">{nutrition.ash_pct}%</span>
                        </div>
                      )}
                      {nutrition.kcal_per_100g && (
                        <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                          <span className="text-sm font-medium text-gray-700">칼로리</span>
                          <span className="text-sm font-bold text-gray-900">{nutrition.kcal_per_100g} kcal/100g</span>
                        </div>
                      )}
                      {nutrition.calcium_pct && (
                        <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                          <span className="text-sm font-medium text-gray-700">칼슘</span>
                          <span className="text-sm font-bold text-gray-900">{nutrition.calcium_pct}%</span>
                        </div>
                      )}
                      {nutrition.phosphorus_pct && (
                        <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                          <span className="text-sm font-medium text-gray-700">인</span>
                          <span className="text-sm font-bold text-gray-900">{nutrition.phosphorus_pct}%</span>
                        </div>
                      )}
                      {nutrition.aafco_statement && (
                        <div className="col-span-2 p-3 bg-gray-50 rounded-lg">
                          <span className="text-sm font-medium text-gray-700 block mb-1">AAFCO 성명</span>
                          <span className="text-sm text-gray-900">{nutrition.aafco_statement}</span>
                        </div>
                      )}
                    </div>
                  ) : (
                    <p className="text-sm text-gray-500">영양 정보가 없습니다.</p>
                  )}
                  <button
                    onClick={() => setShowEditNutrition(true)}
                    className="admin-btn px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white text-sm flex items-center gap-2"
                  >
                    <Plus className="w-4 h-4" />
                    {nutrition && (nutrition.protein_pct || nutrition.fat_pct || nutrition.fiber_pct || nutrition.moisture_pct || nutrition.kcal_per_100g || nutrition.calcium_pct || nutrition.phosphorus_pct) ? '영양 정보 수정' : '영양 정보 추가'}
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* 알레르겐 */}
          <div className="admin-card overflow-hidden">
            <button
              onClick={() => toggleSection('allergens')}
              className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
            >
              <h3 className="font-bold text-gray-900">알레르겐</h3>
              <ChevronDown
                className={`w-5 h-5 text-gray-500 transition-transform ${
                  openSection === 'allergens' ? 'rotate-180' : ''
                }`}
              />
            </button>
            {openSection === 'allergens' && (
              <div className="px-6 pb-6 border-t border-gray-200">
                <div className="pt-4 space-y-3">
                  <div className="flex flex-wrap gap-2">
                    {allergens.length > 0 ? (
                      allergens.map((allergen, idx) => {
                        const code = allergen.code || allergen.allergen_code;
                        const name = allergen.name || allergen.allergen_name || code;
                        return (
                          <span
                            key={idx}
                            className="px-3 py-1 bg-red-50 text-red-700 text-sm rounded-full flex items-center gap-2"
                          >
                            {name}
                            <button
                              onClick={() => handleDeleteAllergen(code)}
                              className="hover:bg-red-100 rounded-full p-0.5"
                            >
                              ×
                            </button>
                          </span>
                        );
                      })
                    ) : (
                      <span className="text-sm text-gray-500">등록된 알레르겐이 없습니다.</span>
                    )}
                  </div>
                  <button
                    onClick={() => setShowAddAllergen(true)}
                    className="admin-btn px-3 py-1.5 bg-gray-100 hover:bg-gray-200 text-gray-700 text-sm flex items-center gap-2"
                  >
                    <Plus className="w-3 h-3" />
                    알레르겐 추가
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* 기능성 클레임 */}
          <div className="admin-card overflow-hidden">
            <button
              onClick={() => toggleSection('claims')}
              className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
            >
              <h3 className="font-bold text-gray-900">기능성 클레임</h3>
              <ChevronDown
                className={`w-5 h-5 text-gray-500 transition-transform ${
                  openSection === 'claims' ? 'rotate-180' : ''
                }`}
              />
            </button>
            {openSection === 'claims' && (
              <div className="px-6 pb-6 border-t border-gray-200">
                <div className="pt-4 space-y-3">
                  <div className="flex flex-wrap gap-2">
                    {claims.length > 0 ? (
                      claims.map((claim, idx) => {
                        const code = claim.code || claim.claim_code;
                        const name = claim.name || claim.claim_name || code;
                        return (
                          <span
                            key={idx}
                            className="px-3 py-1 bg-green-50 text-green-700 text-sm rounded-full flex items-center gap-2"
                          >
                            {name}
                            <button
                              onClick={() => handleDeleteClaim(code)}
                              className="hover:bg-green-100 rounded-full p-0.5"
                            >
                              ×
                            </button>
                          </span>
                        );
                      })
                    ) : (
                      <span className="text-sm text-gray-500">등록된 클레임이 없습니다.</span>
                    )}
                  </div>
                  <button
                    onClick={() => setShowAddClaim(true)}
                    className="admin-btn px-3 py-1.5 bg-gray-100 hover:bg-gray-200 text-gray-700 text-sm flex items-center gap-2"
                  >
                    <Plus className="w-3 h-3" />
                    클레임 추가
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* 판매처 */}
          <div className="admin-card overflow-hidden">
            <button
              onClick={() => toggleSection('offers')}
              className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
            >
              <h3 className="font-bold text-gray-900">판매처 (Offers)</h3>
              <ChevronDown
                className={`w-5 h-5 text-gray-500 transition-transform ${
                  openSection === 'offers' ? 'rotate-180' : ''
                }`}
              />
            </button>
            {openSection === 'offers' && (
              <div className="px-6 pb-6 border-t border-gray-200">
                <div className="pt-4 space-y-3">
                  {offers.length > 0 ? (
                    <div className="space-y-2">
                      {offers.map((offer) => (
                        <div key={offer.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                          <div>
                            <div className="font-semibold text-gray-900">
                              {offer.platform || offer.platform_name || merchantToPlatform(offer.merchant) || '기타'}
                            </div>
                            <div className="text-sm text-gray-600">
                              {(offer.price || offer.current_price)
                                ? (offer.price || offer.current_price).toLocaleString() + '원'
                                : '가격 정보 없음'}
                            </div>
                            {offer.url && (
                              <a
                                href={offer.url}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="text-xs text-blue-600 hover:underline"
                              >
                                링크 보기
                              </a>
                            )}
                          </div>
                          <button
                            onClick={() => {
                              setEditingOffer(offer);
                              setShowEditOffer(true);
                            }}
                            className="text-sm text-blue-600 hover:text-blue-700"
                          >
                            수정
                          </button>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-sm text-gray-500">등록된 판매처가 없습니다.</p>
                  )}
                  <button
                    onClick={() => setShowAddOffer(true)}
                    className="admin-btn px-3 py-1.5 bg-blue-500 hover:bg-blue-600 text-white text-sm flex items-center gap-2"
                  >
                    <Plus className="w-3 h-3" />
                    판매처 추가
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Edit Dialog */}
      {showEditDialog && (
        <EditProductDialog
          product={product}
          onClose={() => setShowEditDialog(false)}
          onSave={(updatedProduct) => {
            onUpdate(updatedProduct);
            setShowEditDialog(false);
            toast.success('상품이 수정되었습니다.');
          }}
        />
      )}

      {/* Delete Confirmation */}
      {showDeleteConfirm && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-2xl max-w-md w-full p-6">
            <h3 className="text-lg font-bold text-gray-900 mb-2">상품 삭제</h3>
            <p className="text-sm text-gray-600 mb-6">
              정말로 이 상품을 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.
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

      {/* Add Allergen Dialog */}
      {showAddAllergen && product && (
        <AddAllergenDialog
          product={product}
          onClose={() => setShowAddAllergen(false)}
          onSave={async (allergenCode) => {
            try {
              await productService.addAllergen(product.id, allergenCode);
              await loadProductDetails();
              setShowAddAllergen(false);
              toast.success('알레르겐이 추가되었습니다.');
            } catch (err) {
              const errorMessage = err instanceof ApiError 
                ? `추가 실패: ${err.status} ${err.statusText}`
                : '알레르겐 추가에 실패했습니다.';
              toast.error(errorMessage);
            }
          }}
        />
      )}

      {/* Add Claim Dialog */}
      {showAddClaim && product && (
        <AddClaimDialog
          product={product}
          onClose={() => setShowAddClaim(false)}
          onSave={async (claimCode) => {
            try {
              await productService.addClaim(product.id, claimCode);
              await loadProductDetails();
              setShowAddClaim(false);
              toast.success('클레임이 추가되었습니다.');
            } catch (err) {
              const errorMessage = err instanceof ApiError 
                ? `추가 실패: ${err.status} ${err.statusText}`
                : '클레임 추가에 실패했습니다.';
              toast.error(errorMessage);
            }
          }}
        />
      )}

      {/* Add Offer Dialog */}
      {showAddOffer && product && (
        <AddOfferDialog
          product={product}
          onClose={() => setShowAddOffer(false)}
          onSave={async (offerData) => {
            try {
              await productService.addOffer(product.id, offerData);
              await loadProductDetails();
              setShowAddOffer(false);
              toast.success('판매처가 추가되었습니다.');
            } catch (err) {
              const errorMessage = err instanceof ApiError 
                ? `추가 실패: ${err.status} ${err.statusText}`
                : '판매처 추가에 실패했습니다.';
              toast.error(errorMessage);
            }
          }}
        />
      )}

      {/* Edit Offer Dialog */}
      {showEditOffer && product && editingOffer && (
        <AddOfferDialog
          product={product}
          mode="edit"
          initialData={{
            platform: editingOffer.platform || editingOffer.platform_name || merchantToPlatform(editingOffer.merchant),
            url: editingOffer.url || '',
            price: editingOffer.price || editingOffer.current_price || 0,
          }}
          onClose={() => {
            setShowEditOffer(false);
            setEditingOffer(null);
          }}
          onSave={async (offerData) => {
            try {
              await productService.updateOffer(editingOffer.id, offerData);
              await loadProductDetails();
              setShowEditOffer(false);
              setEditingOffer(null);
              toast.success('판매처가 수정되었습니다.');
            } catch (err) {
              const errorMessage = err instanceof ApiError 
                ? `수정 실패: ${err.status} ${err.statusText}`
                : '판매처 수정에 실패했습니다.';
              toast.error(errorMessage);
            }
          }}
        />
      )}

      {/* Edit Ingredient Dialog */}
      {showEditIngredient && product && (
        <EditIngredientDialog
          product={product}
          onClose={() => setShowEditIngredient(false)}
          onSave={async () => {
            await loadProductDetails();
          }}
        />
      )}

      {/* Edit Nutrition Dialog */}
      {showEditNutrition && product && (
        <EditNutritionDialog
          product={product}
          onClose={() => setShowEditNutrition(false)}
          onSave={async () => {
            await loadProductDetails();
          }}
        />
      )}

      {/* Analysis Preview Modal */}
      {showAnalysisPreview && analysisResult && (
        <IngredientAnalysisPreviewModal
          parsed={analysisResult}
          onClose={() => {
            setShowAnalysisPreview(false);
            setAnalysisResult(null);
          }}
          onSave={handleSaveAnalysis}
          saving={loading.saveParsed || false}
        />
      )}
    </>
  );
}