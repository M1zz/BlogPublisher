# 초보 Swift 개발자가 하기 쉬운 실수 10가지

Swift를 처음 배우는 개발자들이 자주 겪는 실수들을 정리했습니다. 각 실수와 함께 올바른 해결 방법을 예제 코드로 살펴보겠습니다.

## 1. 강제 언래핑(Force Unwrapping) 남용

```swift
// ❌ 잘못된 예시
let name: String? = nil
print(name!) // 런타임 크래시!

// ✅ 올바른 예시
let name: String? = nil
if let name = name {
    print(name)
} else {
    print("이름이 없습니다")
}

// 또는 nil-coalescing 연산자 사용
print(name ?? "기본값")
```

## 2. 순환 참조(Retain Cycle) 발생

```swift
// ❌ 잘못된 예시
class ViewController {
    var onComplete: (() -> Void)?

    func setup() {
        onComplete = {
            self.doSomething() // self를 강하게 참조 → 메모리 누수
        }
    }
}

// ✅ 올바른 예시
class ViewController {
    var onComplete: (() -> Void)?

    func setup() {
        onComplete = { [weak self] in
            self?.doSomething()
        }
    }
}
```

## 3. == 와 === 혼동

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

// ✅ 올바른 이해
person1 === person3 // true (같은 인스턴스)
```

## 4. 배열 인덱스 범위 초과

```swift
// ❌ 잘못된 예시
let numbers = [1, 2, 3]
let value = numbers[5] // 크래시!

// ✅ 올바른 예시
let numbers = [1, 2, 3]

// 방법 1: 범위 체크
if numbers.indices.contains(5) {
    let value = numbers[5]
}

// 방법 2: 안전한 subscript 확장
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

let value = numbers[safe: 5] // nil 반환
```

## 5. struct와 class 차이 무시

```swift
// struct는 값 타입 (복사됨)
struct Point {
    var x: Int
    var y: Int
}

var point1 = Point(x: 0, y: 0)
var point2 = point1
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
var loc2 = loc1
loc2.x = 10

print(loc1.x) // 10 (같이 변경됨!)
print(loc2.x) // 10
```

## 6. 메인 스레드에서 UI 업데이트 안 함

```swift
// ❌ 잘못된 예시
func fetchData() {
    URLSession.shared.dataTask(with: url) { data, _, _ in
        self.label.text = "완료" // 백그라운드 스레드에서 UI 업데이트 → 문제!
    }.resume()
}

// ✅ 올바른 예시
func fetchData() {
    URLSession.shared.dataTask(with: url) { data, _, _ in
        DispatchQueue.main.async {
            self.label.text = "완료"
        }
    }.resume()
}

// 또는 Swift Concurrency 사용
func fetchData() async {
    let data = try? await URLSession.shared.data(from: url)
    await MainActor.run {
        self.label.text = "완료"
    }
}
```

## 7. guard let과 if let 오용

```swift
// ❌ if let 중첩 지옥
func process(data: Data?) {
    if let data = data {
        if let json = try? JSONSerialization.jsonObject(with: data) {
            if let dict = json as? [String: Any] {
                if let name = dict["name"] as? String {
                    print(name)
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
          let name = dict["name"] as? String else {
        return
    }

    print(name)
}
```

## 8. 문자열 비교 시 대소문자 무시 안 함

```swift
// ❌ 잘못된 예시
let input = "Hello"
if input == "hello" {
    print("일치") // 실행 안 됨
}

// ✅ 올바른 예시
let input = "Hello"
if input.lowercased() == "hello" {
    print("일치")
}

// 또는 caseInsensitiveCompare 사용
if input.caseInsensitiveCompare("hello") == .orderedSame {
    print("일치")
}
```

## 9. @escaping 클로저 이해 부족

```swift
// ❌ 컴파일 에러
class DataManager {
    var completion: (() -> Void)?

    func save(completion: () -> Void) {
        self.completion = completion // 에러! @escaping 필요
    }
}

// ✅ 올바른 예시
class DataManager {
    var completion: (() -> Void)?

    func save(completion: @escaping () -> Void) {
        self.completion = completion // OK
    }
}
```

## 10. 옵셔널 체이닝 결과 무시

```swift
// ❌ 잘못된 예시 - 결과가 옵셔널임을 인지 못함
struct User {
    var address: Address?
}

struct Address {
    var city: String
}

let user = User(address: nil)
let city = user.address?.city // String? 타입임!

// city를 String으로 잘못 사용하면 문제 발생

// ✅ 올바른 예시
if let city = user.address?.city {
    print("도시: \(city)")
} else {
    print("주소 정보 없음")
}
```

---

## 마무리

이 실수들은 대부분 Swift의 타입 시스템과 메모리 관리 방식을 제대로 이해하면 피할 수 있습니다. 특히:

- **옵셔널**을 항상 안전하게 처리하세요
- **값 타입과 참조 타입**의 차이를 명확히 이해하세요
- **메모리 관리**에서 `weak`와 `unowned`를 적절히 사용하세요
- **비동기 작업**에서는 항상 스레드를 의식하세요

실수를 두려워하지 말고, 컴파일러 경고를 친구로 삼으세요!
