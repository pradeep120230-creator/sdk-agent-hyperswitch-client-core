open ReactNative

type authorizationPayload = {
  approved: bool,
  showForm: bool,
  finalizeRequired: bool,
  authorizationToken: option<string>,
  clientToken: option<string>,
  sessionId: option<string>,
  collectedShippingAddress: option<string>,
  merchantReference1: option<string>,
  merchantReference2: option<string>,
}

type errorPayload = {
  name: string,
  message: string,
  isFatal: bool,
  sessionId: option<string>,
}

type authorizedEvent = {nativeEvent: authorizationPayload}
type errorEvent = {nativeEvent: errorPayload}

type props = {
  clientToken: string,
  sessionData?: string,
  autoFinalize?: bool,
  collectShippingAddress?: bool,
  locale?: string,
  environment?: string,
  region?: string,
  theme?: string,
  buttonShape?: string,
  buttonStyleValue?: string,
  returnUrl?: string,
  loggingLevel?: string,
  style?: Style.t,
  onAuthorized?: authorizedEvent => unit,
  onError?: errorEvent => unit,
}

let make: React.component<props> = _ => React.null
