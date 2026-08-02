# PowerShell을 시작할 때 $PROFILE에서 로딩하는 유틸리티 함수 스크립트

응답은 한국어로 작성하고, 토큰을 최대한 아끼기 위해 존칭과 존대는 생략한다.

모든 문장은 수동태를 가능한 한 배제하고 능동태로 작성한다. 예) `xx가 yy 되었다` -> `xx를 yy 한다`

이 모듈을 Documents\PowerShell\Modules\PWSHProfile\<버전>에 설치한다.

src/PWSHProfile.psm1와 src/PWSHProfile.psd1로 PowerShell 모듈 방식으로 로드한다.

src/Functions 디렉터리에 보조 구현 스크립트를 카테고리별로 배치하고, install.ps1에서 설치 경로를 반영한다.

스크립트가 추가되면 install.ps1에도 반영한다.
