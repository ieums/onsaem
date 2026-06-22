import 'package:flutter/material.dart';
import 'package:ieum/core/utils/date_format_util.dart';

/// 학생 복습 탭 더미 데이터
abstract final class StudentReviewDummyData {
  static final referenceDate = DateTime(2024, 5, 18, 19, 32, 10);

  static const subjectFilters = ['전체', '국어', '수학', '영어', '사회', '과학'];
  static const listPageSize = 20;

  /// [StudentHomeDummyData.recentLessons] 와 id·과목·강사·수업일시 일치
  static final items = <StudentReviewItem>[
    StudentReviewItem(
      id: 'rl-1',
      subject: '수학',
      recordedAt: DateTime(2024, 5, 18, 19, 32, 10),
      title: '이 문제풀이에 미분 활용이 왜 꼭 필요한지에 대해 궁금해요!',
      tutorName: '김선생',
      videoDurationSeconds: 2732,
      initialPositionSeconds: 0,
      isBookmarked: true,
      showReviewingBadge: true,
      summaryProblem:
          '주어진 함수의 극값과 변곡점을 구하는 과정에서 미분이 왜 필수적인지, '
          '그래프 개형과 연결해 설명해 달라고 질문했습니다.',
      summarySolution:
          '강사는 f\'(x)=0에서 극값 후보를 구하고, f\'\'(x) 부호로 극대·극소를 판별한 뒤 '
          '변곡점은 f\'\'(x)=0에서 확인한다고 풀이했습니다. 마지막에 그래프를 함께 '
          '그리며 증가·감소 구간을 정리했습니다.',
      conceptDetail: StudentReviewConceptDetail(
        intro:
            '미분은 함수가 특정 지점에서 얼마나 가파르게 변하는지를 나타내는 도구입니다. '
            '문제에서 함수의 개형을 그리거나 극값·변곡점을 찾을 때, 미분값의 부호와 '
            '크기를 해석하는 것이 핵심입니다.',
        graph: StudentReviewConceptGraph(
          type: StudentReviewConceptGraphType.line,
          title: 'f\'(x) 부호와 그래프 개형',
          caption:
              'f\'(x)>0 구간에서는 함수가 증가하고, f\'(x)<0 구간에서는 감소합니다. '
              '기울기가 0이 되는 지점이 극값 후보입니다.',
          axisLabels: const ['a', 'b', 'c', 'd'],
          lineSegments: const [
            StudentReviewGraphSegment(
              startY: 0.15,
              endY: 0.75,
              length: 1,
              color: Color(0xFF4CAF50),
              fill: true,
            ),
            StudentReviewGraphSegment(
              startY: 0.75,
              endY: 0.35,
              length: 1,
              color: Color(0xFFE57373),
            ),
            StudentReviewGraphSegment(
              startY: 0.35,
              endY: 0.85,
              length: 1,
              color: Color(0xFF4CAF50),
              fill: true,
            ),
          ],
          legend: const [
            StudentReviewGraphLegendItem(
              label: '증가 (f\'>0)',
              color: Color(0xFF4CAF50),
            ),
            StudentReviewGraphLegendItem(
              label: '감소 (f\'<0)',
              color: Color(0xFFE57373),
            ),
          ],
        ),
        sections: const [
          StudentReviewConceptSection(
            title: '1차 미분 f\'(x) — 증가·감소와 극값',
            body:
                'f\'(x)는 접선의 기울기입니다. f\'(x)>0이면 x가 커질 때 y도 커지므로 증가 구간, '
                'f\'(x)<0이면 감소 구간입니다.',
            bullets: [
              'f\'(x)=0인 x를 극값 후보로 잡습니다.',
              '후보점 전후의 f\'(x) 부호가 +에서 −로 바뀌면 극대, −에서 +로 바뀌면 극소입니다.',
              '증감표를 그리면 그래프 개형을 빠르게 스케치할 수 있습니다.',
            ],
          ),
          StudentReviewConceptSection(
            title: '2차 미분 f\'\'(x) — 오목·볼록과 변곡점',
            body:
                'f\'\'(x)>0이면 아래로 볼록(오목), f\'\'(x)<0이면 위로 볼록(볼록)입니다. '
                '변곡점은 오목·볼록성이 바뀌는 지점으로 f\'\'(x)=0에서 찾습니다.',
            bullets: [
              'f\'\'(a)>0이면 x=a에서 극소 가능성이 높습니다.',
              'f\'\'(a)<0이면 x=a에서 극대 가능성이 높습니다.',
              '변곡점은 f\'\'(x)의 부호가 바뀌는지 꼭 확인합니다.',
            ],
          ),
          StudentReviewConceptSection(
            title: '그래프로 풀이 연결하기',
            body:
                '미분 결과를 표로 정리한 뒤, x축 위에 증가·감소 화살표를 그리면 '
                '함수의 대략적인 모양을 바로 떠올릴 수 있습니다.',
            bullets: [
              '극값 후보 → y좌표 계산 → 변곡점 → 점근선 순으로 그리면 실수가 줄어듭니다.',
              '실수 문제에서는 구간별로 f\'(x) 부호만 맞아도 절반은 해결됩니다.',
            ],
          ),
        ],
        relatedTips: const [
          '(e^x)\' = e^x — 지수함수는 미분해도 형태가 유지됩니다.',
          '합성함수는 겉미분 × 속미분(연쇄법칙)으로 빠르게 처리하세요.',
          '극값 판별은 f\'\'(x) 판별법과 증감표법 중 편한 방법을 선택하면 됩니다.',
          '변곡점은 f\'\'(x)=0만으로 끝내지 말고 부호 변화를 반드시 확인하세요.',
        ],
      ),
    ),
    StudentReviewItem(
      id: 'rl-2',
      subject: '영어',
      recordedAt: DateTime(2024, 5, 15, 16, 45, 28),
      title: '관계대명사 that과 which의 차이를 수능 지문 예시로 설명해 주세요.',
      tutorName: '이선생',
      videoDurationSeconds: 1938,
      initialPositionSeconds: 0,
      isBookmarked: false,
      showReviewingBadge: false,
      summaryProblem:
          '수능 지문에서 관계대명사 that과 which를 구분하는 기준과, '
          '콤마 유무에 따른 제한적·비제한적 용법 차이를 예문으로 물었습니다.',
      summarySolution:
          'that은 제한적 용법(필수 정보)에, which는 비제한적(부가 정보, 콤마)에 자주 쓰인다고 설명했고, '
          '실제 기출 문장 두 개를 비교하며 선행사와의 필수성 여부로 구분하는 방법을 정리했습니다.',
      conceptDetail: StudentReviewConceptDetail(
        intro:
            '관계대명사 that과 which는 모두 선행사를 꾸며 주지만, 문장에서 정보의 필수성과 '
            '콤마 사용 여부에 따라 용법이 달라집니다. 수능에서는 문맥상 빼도 되는 정보인지 '
            '판단하는 것이 가장 중요합니다.',
        graph: StudentReviewConceptGraph(
          type: StudentReviewConceptGraphType.comparison,
          title: 'that vs which 한눈에 비교',
          caption: '콤마와 문맥(필수/부가 정보)을 함께 보면 선택이 쉬워집니다.',
            comparisonItems: const [
            StudentReviewComparisonItem(
              title: 'that',
              accentColor: Color(0xFF5C7CFA),
              bullets: [
                '제한적 용법 — 문장에 꼭 필요한 정보',
                '콤마 없이 선행사를 구체적으로 한정',
                '정보를 빼면 의미가 불완전해짐',
              ],
            ),
            StudentReviewComparisonItem(
              title: 'which',
              accentColor: Color(0xFF12B886),
              bullets: [
                '비제한적 용법 — 부가 설명',
                '앞에 콤마를 두는 경우가 많음',
                '생략해도 핵심 의미는 유지됨',
              ],
            ),
          ],
        ),
        sections: const [
          StudentReviewConceptSection(
            title: '제한적 용법 (that)',
            body:
                '선행사를 꾸미는 정보가 문장 성립에 꼭 필요할 때 사용합니다. '
                '정보를 빼면 앞 명사가 무엇을 가리키는지 불분명해집니다.',
            bullets: [
              'The book that I bought is useful. → 내가 산 책 (어떤 책인지 특정)',
              '사람·사물 모두 that 사용 가능',
              '구어체에서는 which 대신 that을 더 자주 씁니다.',
            ],
          ),
          StudentReviewConceptSection(
            title: '비제한적 용법 (which)',
            body:
                '부가 설명을 덧붙일 때 쓰며, 앞에 콤마가 붙는 경우가 많습니다. '
                '절을 빼도 문장의 핵심 의미는 유지됩니다.',
            bullets: [
              'My laptop, which I bought last year, is slow. → 노트북에 대한 부가 정보',
              '콤마 + which 패턴을 기출에서 자주 확인하세요.',
              'which는 주로 사물 선행사와 함께 쓰입니다.',
            ],
          ),
          StudentReviewConceptSection(
            title: '수능 지문에서의 판별법',
            body:
                '절을 괄호로 묶어 봤을 때 문장이 자연스럽게 읽히면 비제한적(which), '
                '핵심 정보가 사라지면 제한적(that)일 가능성이 큽니다.',
            bullets: [
              '콤마 유무는 강한 힌트지만, 무조건 which는 아닙니다.',
              '선행사가 유일한 대상이면 which로 부가 설명을 붙이기도 합니다.',
            ],
          ),
        ],
        relatedTips: const [
          '관계부사 where/when은 장소·시간 선행사를 연결할 때 사용합니다.',
          '전치사 + which 구조( in which, of which )는 빈칸 추론에 자주 나옵니다.',
          'that은 전치사 뒤에 오지 않는 경우가 많습니다. (the way in which O)',
          '두 절을 and/when/because로 나눠 읽어 보면 용법 판별이 쉬워집니다.',
        ],
      ),
    ),
    StudentReviewItem(
      id: 'rl-3',
      subject: '과학',
      recordedAt: DateTime(2024, 5, 10, 14, 20, 00),
      title: '뉴턴 제2법칙과 에너지 보존 법칙을 연결해서 설명해 주실 수 있나요?',
      tutorName: '최선생',
      videoDurationSeconds: 1685,
      initialPositionSeconds: 0,
      isBookmarked: true,
      showReviewingBadge: true,
      summaryProblem:
          '힘과 가속도 관계(F=ma)로 설명한 운동이 에너지 보존 법칙과 '
          '어떻게 같은 현상을 다른 관점에서 설명하는지 질문했습니다.',
      summarySolution:
          '등가속도 운동 예제에서 F=ma로 가속도를 구하고, 일-에너지 정리 W=Fd로 '
          '운동 에너지 변화를 계산해 두 결과가 일치함을 보였습니다.',
      conceptDetail: StudentReviewConceptDetail(
        intro:
            '역학에서는 같은 운동을 힘의 관점(F=ma)과 에너지의 관점(일-에너지 정리)으로 '
            '모두 설명할 수 있습니다. 두 방법의 결과가 일치한다는 점을 이해하면 '
            '문제 유형에 맞는 풀이 전략을 고를 수 있습니다.',
        graph: StudentReviewConceptGraph(
          type: StudentReviewConceptGraphType.bar,
          title: '역학적 에너지 변화 (마찰 있는 경우)',
          caption:
              '마찰이 있으면 일부 역학적 에너지가 열에너지로 전환되어 '
              '초기 에너지보다 최종 역학적 에너지가 줄어듭니다.',
          barItems: const [
            StudentReviewBarItem(
              label: '초기 에너지',
              value: 1.0,
              color: Color(0xFF5C7CFA),
            ),
            StudentReviewBarItem(
              label: '운동 에너지',
              value: 0.72,
              color: Color(0xFF12B886),
            ),
            StudentReviewBarItem(
              label: '열 손실',
              value: 0.28,
              color: Color(0xFFE57373),
            ),
          ],
        ),
        sections: const [
          StudentReviewConceptSection(
            title: '뉴턴 제2법칙 F = ma',
            body:
                '물체에 가해진 알짜힘은 질량과 가속도의 곱과 같습니다. '
                '힘의 방향과 가속도 방향은 항상 같습니다.',
            bullets: [
              '등가속도 운동: v = v₀ + at, x = v₀t + ½at²',
              '알짜힘이 0이면 등속 직선 운동',
              '여러 힘이 작용하면 벡터 합으로 알짜힘을 구합니다.',
            ],
          ),
          StudentReviewConceptSection(
            title: '일-에너지 정리',
            body:
                '물체에 한 일은 운동 에너지 변화와 같습니다. W = ΔK = ½mv² − ½mv₀² '
                '마찰·저항이 있으면 역학적 에너지 일부가 열로 변합니다.',
            bullets: [
              'W = Fd cos θ — 힘과 변위 방향이 중요합니다.',
              '마찰력의 일은 항상 음수(역학적 에너지 감소)',
              '보존력(중력, 탄성력)의 일은 경로와 무관합니다.',
            ],
          ),
          StudentReviewConceptSection(
            title: '두 관점 연결하기',
            body:
                'F=ma로 가속도를 구한 뒤 속도·변위를 구하고, 같은 결과를 W=Fd로 '
                '검증하면 개념 이해가 확실해집니다.',
            bullets: [
              '힘을 알 때 → F=ma로 운동 상태 변화 분석',
              '거리·속도를 알 때 → 일-에너지 정리가 더 빠를 수 있음',
              '마찰이 있으면 에너지 수지식에 열 손실 항을 포함하세요.',
            ],
          ),
        ],
        relatedTips: const [
          '역학적 에너지 보존은 마찰·공기저항이 없을 때만 성립합니다.',
          '일의 단위 J(줄) = N·m, 에너지 단위와 같습니다.',
          '수평면에서 마찰력 f = μN 으로 마찰 일 W_f = −fd 를 계산합니다.',
          '운동량-충격량 정리(I = Δp)도 충돌 문제에서 함께 활용됩니다.',
        ],
      ),
    ),
    StudentReviewItem(
      id: 'rl-4',
      subject: '국어',
      recordedAt: DateTime(2024, 5, 8, 11, 05, 42),
      title: '비문학 지문에서 필자의 논지와 근거를 어떻게 연결해 읽어야 할까요?',
      tutorName: '박선생',
      videoDurationSeconds: 2145,
      initialPositionSeconds: 0,
      isBookmarked: false,
      showReviewingBadge: false,
      summaryProblem:
          '수능 비문학 지문에서 필자의 핵심 주장을 찾고, '
          '각 문단의 근거가 논지를 어떻게 뒷받침하는지 질문했습니다.',
      summarySolution:
          '강사는 「주장 → 근거 → 예시 → 재강조」 흐름으로 지문을 나누고, '
          '접속어(그러나, 따라서)를 기준으로 논지 전환 지점을 표시하는 방법을 알려줬습니다.',
      conceptDetail: StudentReviewConceptDetail(
        intro:
            '비문학 독해에서는 필자가 무엇을 주장하는지(논지)와 '
            '왜 그렇게 말하는지(근거)를 연결해 읽는 것이 핵심입니다.',
        graph: StudentReviewConceptGraph(
          type: StudentReviewConceptGraphType.comparison,
          title: '논지 vs 근거 구분',
          caption: '주장은 필자의 견해, 근거는 주장을 뒷받침하는 이유·자료입니다.',
          comparisonItems: const [
            StudentReviewComparisonItem(
              title: '논지',
              accentColor: Color(0xFF5C7CFA),
              bullets: [
                '필자가 말하고자 하는 핵심 주장',
                '「무엇을 말하는가」에 해당',
                '제목·결론부에서 자주 확인',
              ],
            ),
            StudentReviewComparisonItem(
              title: '근거',
              accentColor: Color(0xFF12B886),
              bullets: [
                '주장을 뒷받침하는 이유와 자료',
                '「왜 그런가」에 해당',
                '예시·통계·인용 등으로 제시',
              ],
            ),
          ],
        ),
        sections: const [
          StudentReviewConceptSection(
            title: '논지 찾기',
            body: '지문 전체를 관통하는 필자의 핵심 생각입니다.',
            bullets: [
              '첫 문단과 마지막 문단을 먼저 읽습니다.',
              '「따라서」「결국」 뒤에 논지가 올 때가 많습니다.',
              '보기와 비교할 때 논지를 한 문장으로 요약해 봅니다.',
            ],
          ),
          StudentReviewConceptSection(
            title: '근거 연결하기',
            body: '각 문단이 논지를 어떻게 뒷받침하는지 화살표로 연결해 봅니다.',
            bullets: [
              '예시·통계·전문가 인용은 근거의 대표 유형입니다.',
              '「그러나」 이후는 반론·양보 → 논지가 바뀌지 않았는지 확인합니다.',
            ],
          ),
        ],
        relatedTips: const [
          '지문 옆에 「주」「근」 표시만 해도 정답률이 올라갑니다.',
          '선택지는 지문 문장을 그대로 옮긴 함정이 많으니 논지와 비교하세요.',
        ],
      ),
    ),
    StudentReviewItem(
      id: 'rl-5',
      subject: '사회',
      recordedAt: DateTime(2024, 5, 5, 10, 18, 33),
      title: '인구 구조 변화가 노동 시장과 경제 성장에 미치는 영향을 정리해 주세요.',
      tutorName: '정선생',
      videoDurationSeconds: 1920,
      initialPositionSeconds: 0,
      isBookmarked: true,
      showReviewingBadge: false,
      summaryProblem:
          '고령화·저출산으로 인구 구조가 변할 때 노동력과 경제 성장률이 '
          '어떻게 달라지는지 개념적으로 질문했습니다.',
      summarySolution:
          '생산 가능 인구 비율 감소 → 잠재 성장률 하락 → 복지 부담 증가 '
          '흐름으로 설명했고, 사례 그래프로 연령별 인구 피라미드 변화를 함께 봤습니다.',
      conceptDetail: StudentReviewConceptDetail(
        intro:
            '인구 구조는 노동력 공급과 소비 패턴을 결정합니다. '
            '고령화·저출산은 경제 전반에 장기적인 영향을 줍니다.',
        graph: StudentReviewConceptGraph(
          type: StudentReviewConceptGraphType.bar,
          title: '연령별 인구 비중 변화 (예시)',
          caption: '생산연령 인구(15~64세) 비중 감소가 경제 성장에 부담이 됩니다.',
          barItems: const [
            StudentReviewBarItem(
              label: '생산연령',
              value: 0.68,
              color: Color(0xFF5C7CFA),
            ),
            StudentReviewBarItem(
              label: '유년층',
              value: 0.12,
              color: Color(0xFF12B886),
            ),
            StudentReviewBarItem(
              label: '고령층',
              value: 0.20,
              color: Color(0xFFE57373),
            ),
          ],
        ),
        sections: const [
          StudentReviewConceptSection(
            title: '인구 구조와 노동력',
            body: '생산 가능 인구가 줄면 잠재 GDP 성장률이 낮아질 수 있습니다.',
            bullets: [
              '고령화 → 노동 참여율·생산성 변화',
              '저출산 → 미래 노동력 부족',
            ],
          ),
          StudentReviewConceptSection(
            title: '경제·복지 영향',
            body: '연금·의료 등 복지 지출 증가와 세수 구조 변화가 이어집니다.',
            bullets: [
              '생산연령 대비 부양비(dependency ratio) 상승',
              '소비·저축·투자 패턴의 장기 변화',
            ],
          ),
        ],
        relatedTips: const [
          '인구 피라미드와 경제 지표를 함께 외우면 서술형에 유리합니다.',
          '생산연령 인구 = 총인구 − (0~14세 + 65세 이상) 공식을 기억하세요.',
        ],
      ),
    ),
    StudentReviewItem(
      id: 'rl-6',
      subject: '수학',
      recordedAt: DateTime(2024, 5, 2, 18, 52, 14),
      title: '확률 문제에서 순열과 조합, 중복을 어떻게 구분해야 하나요?',
      tutorName: '한선생',
      videoDurationSeconds: 1588,
      initialPositionSeconds: 0,
      isBookmarked: false,
      showReviewingBadge: true,
      summaryProblem:
          '경우의 수 문제에서 순서를 고려해야 하는지, '
          '중복 선택인지 판별하는 기준을 예제로 질문했습니다.',
      summarySolution:
          '「나열하면 달라지는가?」「같은 것을 여러 번 고르는가?」 두 질문으로 '
          '순열·조합·중복순열·중복조합을 구분하는 방법을 정리했습니다.',
      conceptDetail: StudentReviewConceptDetail(
        intro:
            '경우의 수는 순서(순열)와 중복 여부에 따라 공식이 달라집니다. '
            '문제 상황을 먼저 분류하는 것이 풀이의 절반입니다.',
        graph: StudentReviewConceptGraph(
          type: StudentReviewConceptGraphType.comparison,
          title: '순열 vs 조합',
          caption: '순서가 중요하면 순열, 순서가 없으면 조합을 사용합니다.',
          comparisonItems: const [
            StudentReviewComparisonItem(
              title: '순열 nPr',
              accentColor: Color(0xFF5C7CFA),
              bullets: [
                '순서가 달라지면 다른 경우',
                '예: 줄 세우기, 자리 배치',
              ],
            ),
            StudentReviewComparisonItem(
              title: '조합 nCr',
              accentColor: Color(0xFF12B886),
              bullets: [
                '순서와 관계없이 선택만 구분',
                '예: 대표 선출, 조합 선택',
              ],
            ),
          ],
        ),
        sections: const [
          StudentReviewConceptSection(
            title: '판별 순서',
            body: '문제를 읽고 먼저 순서·중복 여부를 체크합니다.',
            bullets: [
              '1) 순서가 다른 경우를 구분하는가?',
              '2) 같은 원소를 여러 번 고를 수 있는가?',
            ],
          ),
          StudentReviewConceptSection(
            title: '공식 선택',
            body: '분류표에 따라 nPr, nCr, nHr, nHr 조합 공식을 적용합니다.',
            bullets: [
              '순열: n! / (n−r)!',
              '조합: n! / (r!(n−r)!)',
              '헷갈리면 작은 수 예시(3명 중 2명)로 직접 세어 확인',
            ],
          ),
        ],
        relatedTips: const [
          '「적어도」「최대」는 여사건(전체−경우)으로 풀면 편합니다.',
          '같은 조건의 문제는 분류 → 공식 → 검산 순서로 연습하세요.',
        ],
      ),
    ),
  ];

  static StudentReviewItem? findById(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }
}

class StudentReviewItem {
  StudentReviewItem({
    required this.id,
    required this.subject,
    required this.recordedAt,
    required this.title,
    required this.tutorName,
    required this.videoDurationSeconds,
    required this.initialPositionSeconds,
    required this.isBookmarked,
    required this.showReviewingBadge,
    required this.summaryProblem,
    required this.summarySolution,
    required this.conceptDetail,
  });

  final String id;
  final String subject;
  final DateTime recordedAt;
  final String title;
  final String tutorName;
  final int videoDurationSeconds;
  final int initialPositionSeconds;
  final bool isBookmarked;
  final bool showReviewingBadge;
  final String summaryProblem;
  final String summarySolution;
  final StudentReviewConceptDetail conceptDetail;

  String get recordedAtLabel => formatDotDateTime(recordedAt);

  String get videoDurationLabel =>
      StudentReviewVideoTime.formatSeconds(videoDurationSeconds);
}

class StudentReviewConceptDetail {
  const StudentReviewConceptDetail({
    required this.intro,
    required this.sections,
    required this.relatedTips,
    this.graph,
  });

  final String intro;
  final List<StudentReviewConceptSection> sections;
  final List<String> relatedTips;
  final StudentReviewConceptGraph? graph;
}

class StudentReviewConceptSection {
  const StudentReviewConceptSection({
    required this.title,
    required this.body,
    this.bullets = const [],
  });

  final String title;
  final String body;
  final List<String> bullets;
}

enum StudentReviewConceptGraphType { line, bar, comparison }

class StudentReviewConceptGraph {
  const StudentReviewConceptGraph({
    required this.type,
    required this.title,
    this.caption = '',
    this.axisLabels = const [],
    this.lineSegments = const [],
    this.barItems = const [],
    this.comparisonItems = const [],
    this.legend = const [],
  });

  final StudentReviewConceptGraphType type;
  final String title;
  final String caption;
  final List<String> axisLabels;
  final List<StudentReviewGraphSegment> lineSegments;
  final List<StudentReviewBarItem> barItems;
  final List<StudentReviewComparisonItem> comparisonItems;
  final List<StudentReviewGraphLegendItem> legend;
}

class StudentReviewGraphSegment {
  const StudentReviewGraphSegment({
    required this.startY,
    required this.endY,
    required this.length,
    required this.color,
    this.fill = false,
  });

  final double startY;
  final double endY;
  final double length;
  final Color color;
  final bool fill;
}

class StudentReviewBarItem {
  const StudentReviewBarItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class StudentReviewComparisonItem {
  const StudentReviewComparisonItem({
    required this.title,
    required this.bullets,
    required this.accentColor,
  });

  final String title;
  final List<String> bullets;
  final Color accentColor;
}

class StudentReviewGraphLegendItem {
  const StudentReviewGraphLegendItem({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;
}

abstract final class StudentReviewVideoTime {
  static String formatSeconds(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
