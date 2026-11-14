include "decisions.xs";

int qStart = -1;
int qSure = -1;

void onPayGold(int answerArray = -1) {
    int player = decisionGetPlayer(answerArray);

    float gold = xsPlayerAttribute(player, cAttributeGold);
    if (gold < 1000) {
        xsChatData("You don't have 1000 gold... Try something else!");
        decisionAsk(qStart, player);
        return;
    }

    /* Remove the gold */
    xsSetPlayerAttribute(player, cAttributeGold, gold - 1000);
    xsChatData("The Khan takes your gold and leaves.");
}

int cObjectKnight = 38;

void onPayKnights(int answerArray = -1) {
    int player = decisionGetPlayer(answerArray);

    int knights = xsGetPlayerUnitIds(player, cObjectKnight);
    if (xsArrayGetSize(knights) < 30) {
        xsChatData("You don't have 30 knights... Try something else!");
        decisionAsk(qStart, player);
        return;
    }

    xsArrayResizeInt(knights, 30);

    /* Send the knights away */
    xsTaskUnits(knights, cActionTypeMove, xsVectorSet(100, 100, 0));
    xsChatData("Your knights now serve the Khan.");
}

void onRefuse(int answerArray = -1) {
    decisionAsk(qSure, decisionGetPlayer(answerArray));
}

void onWar(int answerArray = -1) {
    xsChatData("The Khan declares war!");
}

void onReconsider(int answerArray = -1) {
    decisionAsk(qStart, decisionGetPlayer(answerArray));
}

void main() {
    qStart = decisionCreate("The Khan demands tribute. With what will you pay?");
    decisionAddChoice(qStart, "1000 Gold", "onPayGold");
    decisionAddChoice(qStart, "30 Knights", "onPayKnights");
    decisionAddChoice(qStart, "I won't pay!", "onRefuse");

    qSure = decisionCreateWithChoices("Are you sure? The Khan will attack!", "Yes:::onWar|No, let me reconsider:::onReconsider");

    decisionAsk(qStart, 1);
}
