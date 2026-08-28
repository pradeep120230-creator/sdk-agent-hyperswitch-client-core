open PaymentEvents

// `isAdditionalValid` carries completeness that lives outside the dynamic form
// (today: the installment plan selection) into the status reported to the host.
let useFormStatusEmitter = (
  ~isFocused: bool,
  ~hasRequiredFields: bool,
  ~isFormValid: bool,
  ~isPristine: bool,
  ~isAdditionalValid: bool=true,
) => {
  let emitter = PaymentEvents.usePaymentEventEmitter()
  let prevStatusRef = React.useRef(None)

  React.useEffect(() => {
    if isFocused {
      let isComplete = (!hasRequiredFields || isFormValid) && isAdditionalValid
      let isEmpty = hasRequiredFields && isPristine && !isFormValid
      let status = computeFormStatus(~isComplete, ~isEmpty)
      let statusStr = PaymentEventTypes.formStatusValueToString(status)

      if prevStatusRef.current !== Some(statusStr) {
        let event = PaymentEvents.buildFormStatusEvent(~status)
        let timerId = setTimeout(() => {
          prevStatusRef.current = Some(statusStr)
          emitter.emitFormStatus(~event)
        }, 50)
        Some(() => clearTimeout(timerId))
      } else {
        None
      }
    } else {
      None
    }
  }, (isFocused, hasRequiredFields, isFormValid, isPristine, isAdditionalValid))
}
