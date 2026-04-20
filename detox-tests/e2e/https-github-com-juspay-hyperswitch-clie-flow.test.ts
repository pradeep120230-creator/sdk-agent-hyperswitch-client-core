import * as testIds from "../../src/utility/test/TestUtils.bs.js";
import { device, expect } from "detox";
import {
  profileId,
  visaSandboxCard,
  LAUNCH_PAYMENT_SHEET_BTN_TEXT,
  TIMEOUT_CONFIG,
} from "../fixtures/Constants";
import {
  createTestLogger,
  waitForDemoAppLoad,
  launchPaymentSheet,
  navigateToNormalPaymentSheet,
  enterCardDetails,
  typeTextInInput,
  waitForVisibility,
  waitForUIStabilization,
  dismissKeyboard,
} from "../utils/DetoxHelpers";
import { CreateBody, setCreateBodyForTestAutomation } from "../utils/APIUtils";

const logger = createTestLogger();
let globalStartTime = Date.now();
let testStartTime = globalStartTime;

logger.log("Card Eligibility Block E2E Test Starting at:", globalStartTime);

// Card numbers used by this feature's tests. The backend is expected to be
// configured so that BLOCKED_CARD triggers an eligibility_check → deny
// response (PR #470). ALLOWED_CARD is a regular sandbox Visa that should pass.
const BLOCKED_CARD = {
  cardNumber: "4000000000000002",
  expiryDate: "04/44",
  cvc: "123",
};

const ALLOWED_CARD = visaSandboxCard;

// Exact string rendered by CardElement.res when eligibilityStatus === Denied.
// Source: shared-code/assets/v2/jsons/locales/en.json → cardNotEligibleText
const CARD_NOT_ELIGIBLE_ERROR = "This card is not accepted for this payment.";

describe("Card Eligibility Block Flow E2E", () => {
  beforeAll(async () => {
    testStartTime = Date.now();
    logger.log("CPI & Device Sync Starting at:", testStartTime);

    const createPaymentBody = new CreateBody();
    createPaymentBody.addKey("profile_id", profileId);
    createPaymentBody.addKey("request_external_three_ds_authentication", false);

    await setCreateBodyForTestAutomation(createPaymentBody.get());
    await device.launchApp({
      launchArgs: { detoxEnableSynchronization: 1 },
      newInstance: true,
    });
    await device.enableSynchronization();

    logger.log("CPI & Device Sync finished in:", testStartTime, Date.now());
  });

  beforeEach(async () => {
    await device.launchApp({
      launchArgs: { detoxEnableSynchronization: 1 },
      newInstance: true,
    });
  });

  describe("Happy path", () => {
    it("should accept an eligible card and enable the pay button", async () => {
      testStartTime = Date.now();
      logger.log("Test starting at:", testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      await enterCardDetails(
        ALLOWED_CARD.cardNumber,
        ALLOWED_CARD.expiryDate,
        ALLOWED_CARD.cvc,
        testIds,
      );

      await dismissKeyboard();
      await waitForUIStabilization();

      // No eligibility error for an allowed card.
      await expect(
        element(by.text(CARD_NOT_ELIGIBLE_ERROR)),
      ).not.toBeVisible();

      const payButton = element(by.id(testIds.payButtonTestId));
      await waitForVisibility(payButton, TIMEOUT_CONFIG.get("DEFAULT"));

      logger.log("Test finished in:", testStartTime, Date.now());
    });
  });

  describe("Blocked card — eligibility denied", () => {
    it("should show 'This card is not accepted for this payment.' for a blocked card", async () => {
      testStartTime = Date.now();
      logger.log("Test starting at:", testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      const cardNumberInput = element(by.id(testIds.cardNumberInputTestId));
      await cardNumberInput.tap();
      await cardNumberInput.clearText();
      await typeTextInInput(cardNumberInput, BLOCKED_CARD.cardNumber);

      // Move focus off the field so the eligibility check fires reliably.
      const expiryInput = element(by.id(testIds.expiryInputTestId));
      await expiryInput.tap();
      await typeTextInInput(expiryInput, BLOCKED_CARD.expiryDate);

      const cvcInput = element(by.id(testIds.cvcInputTestId));
      await cvcInput.tap();
      await typeTextInInput(cvcInput, BLOCKED_CARD.cvc);

      await dismissKeyboard();
      // Eligibility check is async — allow time for the network round-trip
      // and the setEligibilityStatus(_ => Denied) state update.
      await waitForUIStabilization(TIMEOUT_CONFIG.get("UI_STABILIZATION"));

      await waitForVisibility(
        element(by.text(CARD_NOT_ELIGIBLE_ERROR)),
        TIMEOUT_CONFIG.get("LONG"),
      );
      await expect(element(by.text(CARD_NOT_ELIGIBLE_ERROR))).toBeVisible();

      logger.log("Test finished in:", testStartTime, Date.now());
    });

    it("should keep showing the eligibility error while the blocked card number remains", async () => {
      testStartTime = Date.now();
      logger.log("Test starting at:", testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      const cardNumberInput = element(by.id(testIds.cardNumberInputTestId));
      await cardNumberInput.tap();
      await cardNumberInput.clearText();
      await typeTextInInput(cardNumberInput, BLOCKED_CARD.cardNumber);

      const expiryInput = element(by.id(testIds.expiryInputTestId));
      await expiryInput.tap();

      await dismissKeyboard();
      await waitForUIStabilization(TIMEOUT_CONFIG.get("UI_STABILIZATION"));

      await waitForVisibility(
        element(by.text(CARD_NOT_ELIGIBLE_ERROR)),
        TIMEOUT_CONFIG.get("LONG"),
      );
      await expect(element(by.text(CARD_NOT_ELIGIBLE_ERROR))).toBeVisible();

      logger.log("Test finished in:", testStartTime, Date.now());
    });
  });

  describe("Blocked card + other validation errors", () => {
    it("should not show the eligibility error for an obviously invalid card number (fails luhn before eligibility fires)", async () => {
      testStartTime = Date.now();
      logger.log("Test starting at:", testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      const cardNumberInput = element(by.id(testIds.cardNumberInputTestId));
      await cardNumberInput.tap();
      await cardNumberInput.clearText();
      await typeTextInInput(cardNumberInput, "1234567890123456");

      const expiryInput = element(by.id(testIds.expiryInputTestId));
      await expiryInput.tap();

      await waitForUIStabilization();

      // CardElement.res gates the eligibility error behind `cardNumberMeta`
      // being error-free — an invalid luhn number should surface
      // "Card number is invalid." and NOT the eligibility error.
      await expect(element(by.text("Card number is invalid."))).toBeVisible();
      await expect(
        element(by.text(CARD_NOT_ELIGIBLE_ERROR)),
      ).not.toBeVisible();

      logger.log("Test finished in:", testStartTime, Date.now());
    });

    it("should not show the eligibility error when the card number field is empty", async () => {
      testStartTime = Date.now();
      logger.log("Test starting at:", testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      await waitForUIStabilization();
      await dismissKeyboard();

      const payButton = element(by.id(testIds.payButtonTestId));
      await payButton.tap();

      await waitForUIStabilization();

      await expect(
        element(by.text("Card Number cannot be empty")),
      ).toBeVisible();
      await expect(
        element(by.text(CARD_NOT_ELIGIBLE_ERROR)),
      ).not.toBeVisible();

      logger.log("Test finished in:", testStartTime, Date.now());
    });
  });

  describe("Edge cases — switching between blocked and allowed cards", () => {
    it("should clear the eligibility error after the user replaces the blocked card number with an allowed one", async () => {
      testStartTime = Date.now();
      logger.log("Test starting at:", testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      const cardNumberInput = element(by.id(testIds.cardNumberInputTestId));
      await cardNumberInput.tap();
      await cardNumberInput.clearText();
      await typeTextInInput(cardNumberInput, BLOCKED_CARD.cardNumber);

      const expiryInput = element(by.id(testIds.expiryInputTestId));
      await expiryInput.tap();

      await dismissKeyboard();
      await waitForUIStabilization(TIMEOUT_CONFIG.get("UI_STABILIZATION"));

      await waitForVisibility(
        element(by.text(CARD_NOT_ELIGIBLE_ERROR)),
        TIMEOUT_CONFIG.get("LONG"),
      );

      // Replace with an allowed card.
      await cardNumberInput.tap();
      await cardNumberInput.clearText();
      await typeTextInInput(cardNumberInput, ALLOWED_CARD.cardNumber);
      await expiryInput.tap();

      await dismissKeyboard();
      await waitForUIStabilization(TIMEOUT_CONFIG.get("UI_STABILIZATION"));

      await expect(
        element(by.text(CARD_NOT_ELIGIBLE_ERROR)),
      ).not.toBeVisible();

      logger.log("Test finished in:", testStartTime, Date.now());
    });

    it("should re-show the eligibility error when an allowed card is replaced with a blocked one", async () => {
      testStartTime = Date.now();
      logger.log("Test starting at:", testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      const cardNumberInput = element(by.id(testIds.cardNumberInputTestId));
      await cardNumberInput.tap();
      await cardNumberInput.clearText();
      await typeTextInInput(cardNumberInput, ALLOWED_CARD.cardNumber);

      const expiryInput = element(by.id(testIds.expiryInputTestId));
      await expiryInput.tap();

      await dismissKeyboard();
      await waitForUIStabilization();

      await expect(
        element(by.text(CARD_NOT_ELIGIBLE_ERROR)),
      ).not.toBeVisible();

      await cardNumberInput.tap();
      await cardNumberInput.clearText();
      await typeTextInInput(cardNumberInput, BLOCKED_CARD.cardNumber);
      await expiryInput.tap();

      await dismissKeyboard();
      await waitForUIStabilization(TIMEOUT_CONFIG.get("UI_STABILIZATION"));

      await waitForVisibility(
        element(by.text(CARD_NOT_ELIGIBLE_ERROR)),
        TIMEOUT_CONFIG.get("LONG"),
      );
      await expect(element(by.text(CARD_NOT_ELIGIBLE_ERROR))).toBeVisible();

      logger.log("Test finished in:", testStartTime, Date.now());
    });
  });
});
