# Optional이 뭔지 몰라서 느낌표(!)를 남발한 흑역사

지금 생각하면 정말 부끄럽지만, Swift를 처음 배울 때 나는 Optional이 뭔지도 모르면서 컴파일러가 시키는 대로 느낌표만 찍어댔다. "오류가 사라졌네? 됐다!" 이런 식이었으니까.

그러다 어느 날, 내가 만든 앱이 사용자 손에서 처음으로 크래시를 일으켰다. 그때의 당황스러움이란... 이 글은 그때의 흑역사와, 그걸 극복하는 과정에서 배운 것들을 정리한 기록이다.

---

## 사건의 발단: 왜 자꾸 물음표가 붙는 거야?

Swift를 처음 배울 때, 가장 짜증났던 게 바로 이것이었다.

```swift
var userName: String
userName = getUserName() // 에러: Value of optional type 'String?' must be unwrapped
```

"뭐야, 분명 String이라고 했잖아?" 하면서 에러 메시지를 읽어봐도 도대체 무슨 소리인지 몰랐다. 그러다 Xcode가 제안하는 Fix를 눌렀더니:

```swift
var userName: String
userName = getUserName()! // Fix 적용
```

오, 에러가 사라졌다! 나는 천재인가? 별 생각 없이 이렇게 느낌표를 붙이는 게 "Swift 문법"인 줄 알았다. 물음표가 붙으면 느낌표를 붙이면 되는구나, 간단하네!

그때의 나는 몰랐다. 이게 얼마나 무서운 습관인지를.

---

## 첫 번째 크래시: 세상이 무너지는 순간

앱을 친구들한테 배포했다. 간단한 메모 앱이었는데, 사용자 프로필 기능도 넣어봤다. 자신감 넘치게 "내가 만든 앱 한번 써봐!"라고 자랑했는데...

5분도 안 돼서 친구한테 카톡이 왔다.

> "야, 이거 프로필 들어가면 앱 꺼지는데?"

뭐?? 내 폰에서는 잘 되는데? 급하게 친구 폰으로 확인해보니, 정말로 프로필 화면에 들어가자마자 앱이 죽어버렸다.

Xcode로 돌아와서 로그를 확인하니 이런 메시지가 나왔다.

```
Fatal error: Unexpectedly found nil while unwrapping an Optional value
```

아... 이게 뭔 소리야. 머리가 하얘졌다.

---

## 범인을 찾다: 느낌표의 저주

문제가 된 코드는 이거였다.

```swift
class ProfileViewController: UIViewController {
    var user: User?

    override func viewDidLoad() {
        super.viewDidLoad()

        // 프로필 정보 표시
        nameLabel.text = user!.name
        emailLabel.text = user!.email
        profileImageView.image = UIImage(named: user!.profileImageName)!
    }
}
```

보이나? 느낌표 잔치다. 나는 user가 항상 있을 거라고 생각했다. 근데 친구는 회원가입을 안 하고 바로 프로필 화면에 들어갔던 것이다.

user가 nil인 상태에서 `user!.name`을 호출하니 당연히 크래시가 날 수밖에. 그제야 느낌표가 "강제로 벗겨낸다"는 의미라는 걸 깨달았다. Optional에 값이 없으면? 앱이 죽는다. 끝.

그 순간 느껴진 감정은... 부끄러움과 자괴감이 반반이었다. "나는 지금까지 시한폭탄을 심으면서 코딩을 했구나."

---

## 해결 과정: Optional과 제대로 친해지기

일단 panic이 가라앉고 나서, Optional이 도대체 뭔지 제대로 공부하기 시작했다.

### 1단계: Optional의 의미를 이해하다

Optional은 "값이 있을 수도 있고, 없을 수도 있다"는 타입이다. Swift는 타입 안정성을 중요하게 여기기 때문에, 값이 없을 가능성이 있다면 반드시 Optional로 표시한다.

```swift
var name: String = "철수"   // 무조건 값이 있어야 함
var age: Int? = nil        // 값이 없을 수도 있음 (Optional)
```

그래서 `String?`은 "String 값이 있을 수도, nil일 수도 있다"는 뜻이었다. 물음표는 경고 표시였던 거다. "얘 조심해! 값이 없을 수도 있어!"

### 2단계: 안전하게 벗기는 방법들

느낌표 대신 사용할 수 있는 안전한 방법들을 하나씩 익혀나갔다.

#### if let - 값이 있으면 벗겨서 써라

```swift
// 내가 쓰던 방식 (위험)
nameLabel.text = user!.name

// 안전한 방식
if let user = user {
    nameLabel.text = user.name
    emailLabel.text = user.email
} else {
    nameLabel.text = "로그인이 필요합니다"
}
```

이렇게 하면 user가 nil일 때도 안전하게 처리할 수 있다. if let 블록 안에서는 user가 확실히 값이 있다고 보장되니까 안심하고 쓸 수 있다.

#### guard let - 값이 없으면 빠져나가라

함수 초반에 전제조건을 확인할 때는 guard let이 더 깔끔하다는 걸 알게 됐다.

```swift
func showProfile() {
    guard let user = user else {
        showLoginScreen()
        return
    }

    // 이제 user는 안전하게 사용 가능
    nameLabel.text = user.name
    emailLabel.text = user.email
    // ... 길고 긴 코드들
}
```

if let을 쓰면 코드가 오른쪽으로 계속 들여쓰기되는데, guard let을 쓰면 "값 없으면 끝내고, 있으면 계속 진행"이라는 흐름이 더 명확하다.

#### Optional Chaining - 연쇄적으로 안전하게

특히 nested된 Optional을 다룰 때 유용했다.

```swift
// 끔찍한 과거
let cityName = user!.address!.city!.name

// 안전한 현재
let cityName = user?.address?.city?.name
```

물음표 하나만으로 "값이 있으면 계속 진행하고, 없으면 nil 반환"이라는 안전장치가 생긴다. 중간에 하나라도 nil이면 전체가 nil이 되지만, 최소한 크래시는 안 난다.

#### nil-coalescing operator - 기본값을 제공하라

Optional이지만 항상 무언가는 보여줘야 할 때 쓴다.

```swift
// 이름이 없으면 "게스트" 표시
nameLabel.text = user?.name ?? "게스트"

// 나이가 없으면 0으로 처리
let age = user?.age ?? 0
```

`??` 연산자는 "왼쪽이 nil이면 오른쪽 값을 써라"라는 뜻이다. 간결하면서도 안전하다.

---

## 재발 방지: 코드 전체를 다시 훑다

배운 걸 바탕으로 코드 전체를 다시 점검했다. 느낌표가 있는 곳마다 "이게 정말 안전한가?"를 물어봤다.

### Before: 느낌표 천지

```swift
class MessageViewController: UIViewController {
    var conversation: Conversation?

    func send() {
        let message = messageTextField.text!
        let userId = currentUser!.id
        let conversationId = conversation!.id

        API.sendMessage(
            text: message,
            from: userId,
            to: conversationId
        ) { result in
            self.messageTextField.text = ""
            self.reloadMessages()
        }
    }
}
```

이 코드는 시한폭탄 덩어리다. text가 빈 문자열일 수도, currentUser가 nil일 수도, conversation이 nil일 수도 있다.

### After: 안전하게 다시 작성

```swift
class MessageViewController: UIViewController {
    var conversation: Conversation?

    func send() {
        guard let message = messageTextField.text, !message.isEmpty else {
            showAlert("메시지를 입력해주세요")
            return
        }

        guard let userId = currentUser?.id else {
            showLoginScreen()
            return
        }

        guard let conversationId = conversation?.id else {
            print("Error: 대화 정보가 없습니다")
            return
        }

        API.sendMessage(
            text: message,
            from: userId,
            to: conversationId
        ) { [weak self] result in
            guard let self = self else { return }

            self.messageTextField.text = ""
            self.reloadMessages()
        }
    }
}
```

코드가 조금 길어졌지만, 훨씬 안전하다. 각 단계에서 문제가 생기면 적절하게 대응한다. 그리고 사용자에게도 뭐가 잘못됐는지 알려줄 수 있다.

---

## 그래도 느낌표를 써야 할 때는?

물론 느낌표가 항상 나쁜 건 아니다. 정말로 값이 100% 있다고 확신할 수 있을 때는 써도 된다.

### IBOutlet은 괜찮다

```swift
@IBOutlet weak var titleLabel: UILabel!
```

Storyboard나 XIB로 연결된 IBOutlet은 화면이 로드되면 자동으로 값이 채워진다. 연결이 제대로 됐다면 nil일 일이 없다. (물론 연결 안 했으면 크래시 나지만, 그건 개발 중에 바로 발견된다)

### 방금 전에 확인한 값

```swift
if user != nil {
    print(user!.name) // 이건 안전하다... 하지만 권장하지 않음
}
```

기술적으로는 안전하지만, 그냥 if let을 쓰는 게 더 Swift답다.

```swift
if let user = user {
    print(user.name) // 이게 더 깔끔하고 안전하다
}
```

### guard나 if로 이미 확인한 경우

```swift
guard let user = user else { return }

// 이 아래에서는 user를 느낌표 없이 사용 가능
print(user.name)  // 이미 unwrap 됨
```

---

## 교훈: 컴파일러는 적이 아니라 친구다

돌이켜보면, Optional은 귀찮은 게 아니라 Swift가 주는 선물이었다. 다른 언어들은 null pointer exception이 런타임에 터지지만, Swift는 컴파일 단계에서 "여기 위험해!"라고 알려준다.

처음에는 "왜 자꾸 물음표를 붙이래?" 하고 짜증났지만, 지금은 오히려 고맙다. Optional 덕분에 내 코드가 언제 크래시 날지 예측 가능해졌으니까.

### 지금은 이렇게 생각한다

- 느낌표는 "나는 확신한다"는 선언이다. 확신이 없다면 쓰지 말자.
- 물음표는 "값이 없을 수도 있다"는 정보다. 무시하지 말고 제대로 처리하자.
- if let, guard let, ??, ?. 같은 도구들은 귀찮은 게 아니라 안전망이다.

### 실무에서의 원칙

요즘은 이런 원칙으로 코드를 짠다.

1. **Optional을 만나면 일단 의심한다** - "이게 정말 nil일 수 있나?"
2. **느낌표를 쓰기 전에 한 번 더 생각한다** - "정말로 100% 확신하나?"
3. **크래시보다는 안전한 실패를 선택한다** - 앱이 죽는 것보다 에러 메시지가 낫다.

---

## 마무리: 흑역사에서 배운 것

그때의 크래시 덕분에 나는 Swift를 제대로 이해하게 됐다. 부끄러운 기억이지만, 그 경험이 없었다면 지금도 폭탄 코드를 양산하고 있었을지도 모른다.

지금 이 글을 읽는 당신도 혹시 느낌표를 남발하고 있다면, 한 번쯤 생각해보길 바란다.

"이 코드는 안전한가? 사용자가 예상치 못한 행동을 했을 때도 괜찮을까?"

그리고 기억하자. Optional은 귀찮은 게 아니라, Swift가 우리를 지켜주는 방법이라는 것을.

---

**P.S.** 그 친구한테는 결국 밥을 사줬다. 베타테스터 고용 비용이라고 생각하기로 했다. 지금 생각하면 그게 내가 한 최고의 투자였다.
