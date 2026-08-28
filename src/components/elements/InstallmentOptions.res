open ReactNative
open Style

// Once past this many plans the list stops growing and starts scrolling.
let maxVisiblePlans = 4

@react.component
let make = (
  ~paymentMethod: string,
  ~setSelectedInstallmentPlan: option<ClientResponseType.installmentPlan> => unit,
  ~showInstallments: bool,
  ~setShowInstallments: bool => unit,
  ~installmentsError: string,
  ~setInstallmentsError: string => unit,
) => {
  let (clientData, _, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  let {gap} = ThemebasedStyle.useThemeBasedStyle()

  let (selectedPlanIndex, setSelectedPlanIndex) = React.useState(_ => None)

  let plans = React.useMemo2(
    () =>
      PaymentUtils.filterInstallmentPlansByPaymentMethod(
        clientData->Option.flatMap(data => data.intent_data.installment_options),
        paymentMethod,
      ),
    (clientData, paymentMethod),
  )
  let currency = clientData->Option.mapOr("", data => data.intent_data.currency)

  // Installments are opt-in and must never survive the block being torn down, so
  // the same idempotent reset runs on mount and on unmount.
  React.useEffect0(() => {
    let resetInstallments = () => {
      setSelectedInstallmentPlan(None)
      setShowInstallments(false)
      setInstallmentsError("")
      setSelectedPlanIndex(_ => None)
    }
    resetInstallments()
    Some(resetInstallments)
  })

  let onToggleInstallments = isSelected => {
    setShowInstallments(isSelected)
    if !isSelected {
      setSelectedInstallmentPlan(None)
      setSelectedPlanIndex(_ => None)
      setInstallmentsError("")
    }
  }

  let planList =
    plans
    ->Array.mapWithIndex((plan, index) =>
      <React.Fragment key={index->Int.toString}>
        <UIUtils.RenderIf condition={index > 0}>
          <Space height=8. />
        </UIUtils.RenderIf>
        <InstallmentOptionItem
          plan
          currency
          isSelected={selectedPlanIndex->Option.mapOr(false, i => i === index)}
          onSelect={() => {
            setSelectedPlanIndex(_ => Some(index))
            setSelectedInstallmentPlan(Some(plan))
            setInstallmentsError("")
          }}
        />
      </React.Fragment>
    )
    ->React.array

  <UIUtils.RenderIf condition={plans->Array.length > 0}>
    <View style={s({marginTop: gap->dp})}>
      <ClickableTextElement
        disabled=false
        initialIconName="checkboxClicked"
        updateIconName=Some("checkboxNotClicked")
        text=InstallmentStrings.payInInstallments
        isSelected=showInstallments
        setIsSelected=onToggleInstallments
        textType={TextWrapper.ModalText}
      />
      <UIUtils.RenderIf condition=showInstallments>
        <Space height=10. />
        <TextWrapper text=InstallmentStrings.choosePlan textType={ModalTextBold} />
        <Space height=8. />
        {plans->Array.length > maxVisiblePlans
          ? <ScrollView
              style={s({maxHeight: 240.->dp})}
              nestedScrollEnabled=true
              keyboardShouldPersistTaps=#handled
              showsVerticalScrollIndicator=false>
              {planList}
            </ScrollView>
          : <View> {planList} </View>}
      </UIUtils.RenderIf>
      <ErrorText text={installmentsError === "" ? None : Some(installmentsError)} />
    </View>
  </UIUtils.RenderIf>
}
