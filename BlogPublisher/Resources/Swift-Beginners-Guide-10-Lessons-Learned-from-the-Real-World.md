# Swift 초보 탈출기: 실전에서 배운 10가지 교훈

Swift를 배우면서 누구나 한 번쯤은 겪는 실수들이 있습니다. 저도 처음엔 이런 실수들로 디버깅에 시간을 많이 낭비했는데, 이제는 자연스럽게 피할 수 있게 되었어요. 여러분도 같은 시행착오를 겪지 않도록, 제 경험을 바탕으로 정리해봤습니다.

---

## 1. 강제 언래핑(Force Unwrapping) 남용

**어디서 자주 발생하나요?**

네트워크 응답을 처리하거나, UserDefaults에서 값을 꺼낼 때, 또는 JSON 파싱할 때 특히 많이 발생합니다. "아 이건 무조건 값이 있을 거야" 하고 느낌표를 찍는 순간, 런타임 크래시의 시작입니다.

```swift
// ❌ 잘못된 예시 - 이렇게 쓰면 100% 크래시 경험
let name: String? = nil
print(name!) // Fatal error: Unexpectedly found nil

// 실제 상황 예시: UserDefaults
let userID = UserDefaults.standard.string(forKey: "userID")!
// 첫 실행 시 userID가 없으면? → 💥 크래시

// ✅ 올바른 예시
let name: String? = nil
if let name = name {
    print(name)
} else {
    print("이름이 없습니다")
}

// 또는 nil-coalescing 연산자 사용
print(name ?? "기본값")

// UserDefaults 안전하게 처리
let userID = UserDefaults.standard.string(forKey: "userID") ?? "guest"
```

**💡 꿀팁**

- IBOutlet은 느낌표를 써도 괜찮습니다. Storyboard와 연결이 제대로 되었다면 nil일 수 없으니까요.
- 그 외의 경우는 거의 항상 `if let`, `guard let`, 또는 `??`를 사용하세요.
- Xcode 경고에 "Force unwrapping"이 나오면 반드시 다시 확인하세요.

---

## 2. 순환 참조(Retain Cycle) 발생

**어디서 자주 발생하나요?**

클로저를 사용할 때, 특히 completion handler나 애니메이션 블록에서 `self`를 캡처할 때 정말 많이 발생합니다. 메모리 누수는 눈에 안 보여서 더 위험해요.

```swift
// ❌ 잘못된 예시
class ViewController {
    var onComplete: (() -> Void)?
    var name = "ViewController"

    func setup() {
        onComplete = {
            print(self.name) // self를 강하게 참조 → 메모리 누수
        }
    }
}

// 실제 상황 예시: 네트워크 호출
class ProfileViewController: UIViewController {
    var apiClient: APIClient?

    func loadProfile() {
        apiClient?.fetchProfile { profile in
            self.updateUI(with: profile) // 순환 참조 발생!
        }
    }
}

// ✅ 올바른 예시
class ViewController {
    var onComplete: (() -> Void)?
    var name = "ViewController"

    func setup() {
        onComplete = { [weak self] in
            guard let self = self else { return }
            print(self.name)
        }
    }
}

// 네트워크 호출도 안전하게
class ProfileViewController: UIViewController {
    var apiClient: APIClient?

    func loadProfile() {
        apiClient?.fetchProfile { [weak self] profile in
            self?.updateUI(with: profile)
        }
    }
}
```

**⚠️ 주의사항**

- `[weak self]`를 쓰면 self가 Optional이 되므로, `self?`로 접근해야 합니다.
- 클로저가 짧고 즉시 실행된다면 `[weak self]`가 필요 없을 수도 있지만, 확실하지 않으면 그냥 쓰는 게 안전합니다.
- Instruments의 Leaks 도구로 메모리 누수를 확인할 수 있습니다.

**💡 꿀팁**

- `unowned`는 self가 절대 nil이 될 수 없을 때만 사용하세요. 확신이 없다면 `weak`를 쓰는 게 안전합니다.
- 애니메이션 블록(`UIView.animate`)은 짧게 실행되고 끝나므로 보통 `[weak self]`가 필요 없습니다.

---

## 3. == 와 === 혼동

**어디서 자주 발생하나요?**

객체 비교할 때, 특히 커스텀 클래스를 다룰 때 헷갈립니다. "같은 데이터를 가진 객체"인지, "메모리 상 같은 인스턴스"인지를 구분해야 해요.

```swift
// == 는 값 비교, === 는 참조(인스턴스) 비교
class Person {
    var name: String
    init(name: String) { self.name = name }
}

let person1 = Person(name: "철수")
let person2 = Person(name: "철수")
let person3 = person1

// ❌ 의도와 다른 결과
person1 === person2 // false (다른 인스턴스)
// person1 == person2 // 컴파일 에러! Person은 Equatable을 채택하지 않음

// ✅ 올바른 이해
person1 === person3 // true (같은 인스턴스)

// 값 비교를 하려면 Equatable 채택
extension Person: Equatable {
    static func == (lhs: Person, rhs: Person) -> Bool {
        return lhs.name == rhs.name
    }
}

// 이제 값 비교 가능
person1 == person2 // true (이름이 같음)
```

**💡 꿀팁**

- `struct`는 기본적으로 `==`를 지원하지만, `class`는 직접 `Equatable`을 구현해야 합니다.
- Array나 Dictionary에서 특정 객체를 찾을 때 이 차이가 중요합니다.
- 디버깅할 때 `===`로 "정말 같은 객체인가?"를 확인하면 유용합니다.

---

## 4. 배열 인덱스 범위 초과

**어디서 자주 발생하나요?**

서버에서 받은 데이터를 처리할 때, 또는 사용자 입력을 배열 인덱스로 사용할 때 자주 발생합니다. "배열에 3개 있을 거야"라고 가정하는 순간 위험합니다.

```swift
// ❌ 잘못된 예시
let numbers = [1, 2, 3]
let value = numbers[5] // Fatal error: Index out of range

// 실제 상황 예시: 테이블뷰
func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let item = items[indexPath.row] // items가 비어있으면? → 💥
}

// ✅ 올바른 예시
let numbers = [1, 2, 3]

// 방법 1: 범위 체크
if numbers.indices.contains(5) {
    let value = numbers[5]
} else {
    print("인덱스 범위 초과")
}

// 방법 2: 안전한 subscript 확장 (강력 추천!)
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

let value = numbers[safe: 5] // nil 반환 (크래시 없음)

// 테이블뷰도 안전하게
func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let item = items[safe: indexPath.row] else { return }
    // item 처리
}
```

**💡 꿀팁**

- `Collection` extension의 `subscript(safe:)`는 프로젝트 시작할 때 꼭 추가하세요. 정말 유용합니다.
- `.first`, `.last`는 Optional을 반환하므로 더 안전합니다.
- 빈 배열에서 `.first`를 호출하면 nil이 반환되지, 크래시가 나지 않습니다.

---

## 5. struct와 class 차이 무시

**어디서 자주 발생하나요?**

데이터 모델을 만들 때 무심코 class를 쓰다가, 값이 예상치 못하게 변경되어 버그가 발생합니다. 특히 SwiftUI에서는 struct와 class의 차이가 정말 중요해요.

```swift
// struct는 값 타입 (복사됨)
struct Point {
    var x: Int
    var y: Int
}

var point1 = Point(x: 0, y: 0)
var point2 = point1 // 복사본 생성
point2.x = 10

print(point1.x) // 0 (영향 없음)
print(point2.x) // 10

// class는 참조 타입 (같은 인스턴스 공유)
class Location {
    var x: Int
    var y: Int
    init(x: Int, y: Int) { self.x = x; self.y = y }
}

var loc1 = Location(x: 0, y: 0)
var loc2 = loc1 // 같은 인스턴스를 가리킴
loc2.x = 10

print(loc1.x) // 10 (같이 변경됨!)
print(loc2.x) // 10

// 실제 상황 예시: 설정 객체
class Settings {
    var isDarkMode = false
}

let settings1 = Settings()
let settings2 = settings1
settings2.isDarkMode = true

print(settings1.isDarkMode) // true (의도하지 않은 변경!)
```

**⚠️ 주의사항**

- **언제 struct를 쓸까?** 데이터를 표현할 때 (예: User, Post, Coordinate)
- **언제 class를 쓸까?** 상태를 공유해야 할 때, 상속이 필요할 때
- SwiftUI는 struct를 선호합니다. View는 모두 struct로 만들어집니다.

**💡 꿀팁**

- 기본적으로 struct를 사용하고, 명확한 이유가 있을 때만 class를 쓰세요.
- Codable을 구현할 때도 struct가 훨씬 편합니다.
- `let`으로 선언한 struct는 내부 프로퍼티도 변경할 수 없지만, class는 프로퍼티 변경이 가능합니다.

---

## 6. 메인 스레드에서 UI 업데이트 안 함

**어디서 자주 발생하나요?**

네트워크 통신 후 UI를 업데이트할 때 정말 많이 발생합니다. 에러 메시지도 명확하지 않아서 "왜 UI가 안 바뀌지?"하고 한참을 헤매게 됩니다.

```swift
// ❌ 잘못된 예시
func fetchData() {
    URLSession.shared.dataTask(with: url) { data, _, _ in
        // 이 코드는 백그라운드 스레드에서 실행됨!
        self.label.text = "완료" // ⚠️ UI 업데이트가 느리거나 안 될 수 있음
        self.tableView.reloadData() // 💥 크래시 가능성
    }.resume()
}

// ✅ 올바른 예시
func fetchData() {
    URLSession.shared.dataTask(with: url) { data, _, _ in
        DispatchQueue.main.async {
            self.label.text = "완료"
            self.tableView.reloadData()
        }
    }.resume()
}

// 또는 Swift Concurrency 사용 (Swift 5.5+)
func fetchData() async {
    let data = try? await URLSession.shared.data(from: url)
    await MainActor.run {
        self.label.text = "완료"
        self.tableView.reloadData()
    }
}

// 더 깔끔하게: @MainActor 사용
@MainActor
func updateUI() {
    // 이 함수는 항상 메인 스레드에서 실행됨
    self.label.text = "완료"
}
```

**⚠️ 주의사항**

- UIKit의 모든 것은 메인 스레드에서만 건드려야 합니다.
- 이를 어기면 크래시가 나거나, UI가 이상하게 업데이트되거나, 아예 업데이트가 안 될 수 있습니다.
- Xcode의 Thread Sanitizer를 켜면 이런 문제를 자동으로 찾아줍니다.

**💡 꿀팁**

- Swift Concurrency(`async/await`)를 사용하면 스레드 관리가 훨씬 쉬워집니다.
- `@MainActor`를 ViewModel이나 View Controller에 붙이면 실수를 줄일 수 있습니다.
- Debug 모드에서는 Main Thread Checker를 활성화하세요 (기본값).

---

## 7. guard let과 if let 오용

**어디서 자주 발생하나요?**

여러 Optional 값을 연속으로 체크할 때, if let을 중첩해서 사용하다 보면 코드가 오른쪽으로 계속 밀려나는 "피라미드 오브 둠"이 생깁니다.

```swift
// ❌ if let 중첩 지옥 (Pyramid of Doom)
func process(data: Data?) {
    if let data = data {
        if let json = try? JSONSerialization.jsonObject(with: data) {
            if let dict = json as? [String: Any] {
                if let name = dict["name"] as? String {
                    if let age = dict["age"] as? Int {
                        print("\(name)님의 나이는 \(age)세입니다")
                    }
                }
            }
        }
    }
}

// ✅ guard let으로 가독성 향상
func process(data: Data?) {
    guard let data = data,
          let json = try? JSONSerialization.jsonObject(with: data),
          let dict = json as? [String: Any],
          let name = dict["name"] as? String,
          let age = dict["age"] as? Int else {
        print("데이터 파싱 실패")
        return
    }

    print("\(name)님의 나이는 \(age)세입니다")
    // 이후 코드가 깔끔하게 이어짐
}
```

**💡 꿀팁**

- **guard let 사용 시기**: 함수 초반에 전제 조건을 확인할 때
- **if let 사용 시기**: Optional 값에 따라 다른 동작을 할 때
- guard를 사용하면 "happy path"(정상 흐름)가 왼쪽 정렬되어 읽기 쉽습니다.

```swift
// guard vs if let 선택 가이드
func example(user: User?) {
    // ✅ guard: 필수 조건 체크
    guard let user = user else {
        showLoginScreen()
        return
    }

    // 이후 코드에서 user 사용
    updateProfile(user)

    // ✅ if let: 선택적 처리
    if let avatar = user.avatar {
        showAvatar(avatar)
    } else {
        showDefaultAvatar()
    }
}
```

---

## 8. 문자열 비교 시 대소문자 무시 안 함

**어디서 자주 발생하나요?**

사용자 입력을 처리할 때, 특히 검색 기능이나 로그인 폼에서 자주 발생합니다. "hello"와 "Hello"를 다르게 취급하면 사용자 경험이 나빠집니다.

```swift
// ❌ 잘못된 예시
let input = "Hello"
if input == "hello" {
    print("일치") // 실행 안 됨
}

// 실제 상황 예시: 검색 기능
func search(query: String, in items: [String]) -> [String] {
    return items.filter { $0 == query } // "iPhone"과 "iphone"이 다른 것으로 취급됨
}

// ✅ 올바른 예시
let input = "Hello"

// 방법 1: lowercased() 사용
if input.lowercased() == "hello" {
    print("일치")
}

// 방법 2: caseInsensitiveCompare 사용
if input.caseInsensitiveCompare("hello") == .orderedSame {
    print("일치")
}

// 검색 기능 개선
func search(query: String, in items: [String]) -> [String] {
    let lowercasedQuery = query.lowercased()
    return items.filter { $0.lowercased().contains(lowercasedQuery) }
}

// 방법 3: localizedCaseInsensitiveContains (더 나은 방법)
func search(query: String, in items: [String]) -> [String] {
    return items.filter { $0.localizedCaseInsensitiveContains(query) }
}
```

**⚠️ 주의사항**

- `lowercased()`는 새로운 String을 생성하므로, 반복문에서 사용할 때는 미리 변환해두세요.
- 한글이나 다른 언어도 고려한다면 `localizedCaseInsensitiveContains`를 사용하세요.

**💡 꿀팁**

- 이메일, 사용자명 같은 것을 저장할 때는 아예 소문자로 변환해서 저장하는 것도 좋은 방법입니다.
- `localizedStandardCompare`를 사용하면 자연스러운 정렬도 가능합니다 (예: "파일1" < "파일2" < "파일10").

---

## 9. @escaping 클로저 이해 부족

**어디서 자주 발생하나요?**

비동기 작업을 다룰 때, 특히 네트워킹이나 애니메이션 completion handler를 만들 때 컴파일 에러가 나서 당황하게 됩니다.

```swift
// ❌ 컴파일 에러
class DataManager {
    var completion: (() -> Void)?

    func save(completion: () -> Void) {
        self.completion = completion
        // 에러: Assigning non-escaping parameter 'completion' to an @escaping closure
    }
}

// ✅ 올바른 예시
class DataManager {
    var completion: (() -> Void)?

    // @escaping을 붙이면 함수가 끝난 후에도 클로저를 저장할 수 있음
    func save(completion: @escaping () -> Void) {
        self.completion = completion // OK!
    }

    func performSave() {
        // 나중에 실행
        DispatchQueue.global().async {
            // 저장 작업...
            DispatchQueue.main.async {
                self.completion?()
            }
        }
    }
}

// 실제 사용 예시: 네트워크 매니저
class NetworkManager {
    func request(completion: @escaping (Result<Data, Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                completion(.success(data))
            }
        }.resume()
    }
}
```

**💡 꿀팁**

- **@escaping이 필요한 경우**: 클로저가 함수가 끝난 후에 실행될 때
  - 네트워크 completion handler
  - 프로퍼티에 저장되는 클로저
  - DispatchQueue.async 안의 클로저
- **@escaping이 필요 없는 경우**: 함수 안에서 즉시 실행되는 클로저
  - `map`, `filter`, `forEach` 같은 고차 함수
  - 동기적으로 실행되는 클로저

---

## 10. 옵셔널 체이닝 결과 무시

**어디서 자주 발생하나요?**

중첩된 Optional 값을 다룰 때, 특히 JSON 파싱이나 복잡한 데이터 구조를 다룰 때 자주 발생합니다. 옵셔널 체이닝을 쓰면 편하지만, 결과가 Optional이라는 걸 잊으면 안 됩니다.

```swift
// ❌ 잘못된 예시 - 결과가 옵셔널임을 인지 못함
struct User {
    var address: Address?
}

struct Address {
    var city: String
}

let user = User(address: nil)
let city = user.address?.city // String? 타입임! (String이 아님)

// 이렇게 쓰면 에러
// let message = "도시: " + city // 컴파일 에러

// ✅ 올바른 예시
if let city = user.address?.city {
    print("도시: \(city)")
} else {
    print("주소 정보 없음")
}

// 또는 nil-coalescing 사용
let city = user.address?.city ?? "알 수 없음"
print("도시: \(city)")

// 실제 상황 예시: 깊은 중첩
struct Response {
    var data: ResponseData?
}

struct ResponseData {
    var user: User?
}

struct User {
    var profile: Profile?
}

struct Profile {
    var displayName: String
}

let response = Response(data: nil)

// ❌ 이렇게 쓰면 displayName이 String?임
let name = response.data?.user?.profile?.displayName

// ✅ 안전하게 처리
if let name = response.data?.user?.profile?.displayName {
    print("이름: \(name)")
} else {
    print("프로필 정보를 불러올 수 없습니다")
}
```

**⚠️ 주의사항**

- 옵셔널 체이닝에서 한 단계라도 nil이면 전체 결과가 nil입니다.
- 메서드를 호출할 때도 결과가 Optional이 됩니다: `user?.getName()` → `String?`
- 심지어 원래 반환 타입이 Optional이면 Double Optional이 됩니다: `user?.getMiddleName()` → `String??`

**💡 꿀팁**

- 옵셔널 체이닝이 3단계 이상 깊어지면, 데이터 구조를 다시 생각해보세요.
- Codable로 JSON을 파싱할 때는 필수 값은 Optional이 아닌 타입으로 선언하세요.
- guard let으로 여러 단계를 한 번에 체크하면 더 안전합니다.

```swift
// 깊은 체이닝 대신 guard로 단계별 체크
func displayProfile(response: Response) {
    guard let data = response.data,
          let user = data.user,
          let profile = user.profile else {
        showError("프로필을 불러올 수 없습니다")
        return
    }

    print("이름: \(profile.displayName)")
}
```

---

## 마무리: 실수를 두려워하지 마세요

이 10가지 실수는 제가 Swift를 배우면서 실제로 겪었던 것들입니다. 처음엔 "왜 이렇게 복잡하게 만들었어?" 하고 불평했지만, 지금은 Swift의 안전 장치들이 얼마나 고마운지 알게 되었어요.

**핵심 원칙 정리**

- **옵셔널**은 귀찮은 게 아니라 안전망입니다. 항상 안전하게 처리하세요.
- **값 타입(struct)과 참조 타입(class)**의 차이를 명확히 이해하세요.
- **메모리 관리**: 클로저에서 self를 캡처할 때는 항상 `[weak self]`를 고려하세요.
- **스레드**: UI는 항상 메인 스레드에서 업데이트하세요.
- **타입 시스템**: 컴파일러 경고와 에러는 여러분의 친구입니다. 무시하지 마세요.

**디버깅 팁**

- Xcode의 경고를 절대 무시하지 마세요. 지금은 작동해도 나중에 버그가 됩니다.
- Thread Sanitizer, Address Sanitizer를 활성화해서 런타임 문제를 조기에 발견하세요.
- 의심스러운 곳에는 `print()` 대신 breakpoint를 걸어서 변수 상태를 확인하세요.

Swift는 안전한 언어입니다. 처음엔 제약이 많아 보이지만, 이 제약들이 나중에 여러분을 수많은 버그로부터 지켜줄 거예요. 화이팅!
