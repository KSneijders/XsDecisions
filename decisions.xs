int arrGroupChoices = -1;
int arrGroupChoiceCallbacks = -1;
int arrGroupQuestions = -1;
int arrGroupCallbacks = -1;

int arrActiveDecisionsToGroupMap = -1;
int arrActiveDecisionsToPlayerMap = -1;
int arrActiveDecisionsToAnswerArrayMap = -1;
int cMarkForClear = 999999996;
int cReadyForDelete = 999999999;

int cChoicePending = 0;

void __initializeDecisions() {
    if (arrActiveDecisionsToGroupMap != -1) {
        return;
    }

    int activeDecisionsSupportCount = 200;  /* Equal to the number of decisions visible at a time (8 players) */
    arrActiveDecisionsToGroupMap = xsArrayCreateInt(activeDecisionsSupportCount, -1);
    arrActiveDecisionsToPlayerMap = xsArrayCreateInt(activeDecisionsSupportCount, -1);
    arrActiveDecisionsToAnswerArrayMap = xsArrayCreateInt(activeDecisionsSupportCount, -1);

    int questionSupportCount = 5;  /* Is expanded automatically */
    arrGroupQuestions = xsArrayCreateString(questionSupportCount, "");
    arrGroupCallbacks = xsArrayCreateString(questionSupportCount, "");
    arrGroupChoices = xsArrayCreateInt(questionSupportCount, -1);
    arrGroupChoiceCallbacks = xsArrayCreateInt(questionSupportCount, -1);
}

int findIndexString(int arrayId = -1, string match = "") {
    for(i = 0; < xsArrayGetSize(arrayId)) {
        if (xsArrayGetString(arrayId, i) == match) {
            return (i);
        }
    }

    return (-1);
}

int findIndexInt(int arrayId = -1, int match = -1) {
    for(i = 0; < xsArrayGetSize(arrayId)) {
        if (xsArrayGetInt(arrayId, i) == match) {
            return (i);
        }
    }

    return (-1);
}

void arrayResizeIntArrayWithDef(int arr = -1, int def = -1) {
    int oldSize = xsArrayGetSize(arr);

    xsArrayResizeInt(arr, oldSize * 2);
    for (i = oldSize; < oldSize * 2) {
        xsArraySetInt(arr, i, def);
    }
}

void arrayResizeStringArrayWithDef(int arr = -1, string def = "") {
    int oldSize = xsArrayGetSize(arr);

    xsArrayResizeString(arr, oldSize * 2);
    for (i = oldSize; < oldSize * 2) {
        xsArraySetString(arr, i, def);
    }
}

void __callFunc(string callable = "", int arg = -1) {
    if (callable == "") {
        return;
    }

    xsAddRuntimeEvent("Scenario Triggers", callable, arg);
    xsAddRuntimeEvent("Random Map", callable, arg);
}

bool decisionWasMade(int arr = -1) {
    if (arr == -1) {
        return (false);
    }

    return (xsArrayGetInt(arr, 0) != -1 && xsArrayGetInt(arr, 1) != -1);
}

int decisionGetPlayer(int arr = -1) {
    if (arr == -1) {
        return (-1);
    }

    return (xsArrayGetInt(arr, 2));
}

string decisionGetChoice(int arr = -1) {
    if (arr == -1) {
        return ("");
    }

    int groupId = xsArrayGetInt(arr, 0);
    int choiceIndex = xsArrayGetInt(arr, 1);

    int choicesArray = xsArrayGetInt(arrGroupChoices, groupId);

    return (xsArrayGetString(choicesArray, choiceIndex));
}

int decisionGetQuestion(int arr = -1) {
    if (arr == -1) {
        return (-1);
    }

    return (xsArrayGetInt(arr, 0));
}

int decisionGetChoiceIndex(int arr = -1) {
    if (arr == -1) {
        return (-1);
    }

    return (xsArrayGetInt(arr, 1));
}

int decisionCreate(string question = "", string callback = "") {
    __initializeDecisions();

    int index = findIndexInt(arrGroupChoices, -1);
    if (index == -1) {
        arrayResizeStringArrayWithDef(arrGroupQuestions);
        arrayResizeStringArrayWithDef(arrGroupCallbacks);
        arrayResizeIntArrayWithDef(arrGroupChoices);
        arrayResizeIntArrayWithDef(arrGroupChoiceCallbacks);

        index = findIndexInt(arrGroupChoices, -1);
    }

    xsArraySetInt(arrGroupChoices, index, xsArrayCreateString(4, ""));
    xsArraySetInt(arrGroupChoiceCallbacks, index, xsArrayCreateString(4, ""));

    xsArraySetString(arrGroupQuestions, index, question);
    xsArraySetString(arrGroupCallbacks, index, callback);

    return (index);
}

void decisionSetChoice(int groupId = -1, string choice = "", string callback = "") {
    if (groupId == -1) {
        return;
    }

    int choicesArray = xsArrayGetInt(arrGroupChoices, groupId);
    int choiceCallbackArray = xsArrayGetInt(arrGroupChoiceCallbacks, groupId);

    int index = findIndexString(choicesArray, "");

    if (index == -1) {
        arrayResizeStringArrayWithDef(choicesArray);
        arrayResizeStringArrayWithDef(choiceCallbackArray);

        index = findIndexString(choicesArray, "");
    }

    xsArraySetString(choicesArray, index, choice);
    xsArraySetString(choiceCallbackArray, index, callback);
}

int decisionCreateWithChoices(string question = "", string pipeSeparatedChoices = "", string callback = "") {
    int choices = strSplit(pipeSeparatedChoices, "|");

    string choice = "";
    string choiceCallback = "";

    int groupId = decisionCreate(question, callback);
    for (i = 0; < xsArrayGetSize(choices)) {
        choice = xsArrayGetString(choices, i);
        choiceCallback = "";

        if (strContains(choice, ":::")) {
            int choiceSegments = strSplit(choice, ":::");
            choice = xsArrayGetString(choiceSegments, 0);
            choiceCallback = xsArrayGetString(choiceSegments, 1);
        }

        decisionSetChoice(groupId, choice, choiceCallback);
    }

    return (groupId);
}

/** @allow_discard */
int decisionAsk(int groupId = -1, int player = -1) {
    if (groupId == -1) {
        return (-1);
    }

    string groupQuestion = xsArrayGetString(arrGroupQuestions, groupId);

    int choicesArray = xsArrayGetInt(arrGroupChoices, groupId);
    int choiceCallbackArray = xsArrayGetInt(arrGroupChoiceCallbacks, groupId);

    int numberOfChoiceSlots = xsArrayGetSize(choicesArray);

    /* Fix the size of the array to the current  */
    int actualChoiceCount = findIndexString(choicesArray, "");
    if (actualChoiceCount == -1) {
        actualChoiceCount = xsArrayGetSize(choicesArray);
    }

    if (numberOfChoiceSlots != actualChoiceCount) {
        xsArrayResizeString(choicesArray, actualChoiceCount);
        xsArrayResizeString(choiceCallbackArray, actualChoiceCount);
    }

    int size = xsArrayGetSize(choicesArray);
    int numberOfDecisions = xsCeilToInt((0.0 + size) / 2);

    int answerArray = xsArrayCreateInt(3, -1);

    for (i = 0; < numberOfDecisions) {
        int decisionId = findIndexInt(arrActiveDecisionsToGroupMap, -1);
        if (decisionId == -1) {
            xsChatData(cColorRed + "[Fatal Error] Failed to create decision: No decision array slots remaining");
            return (-1);
        }

        string question = "";
        if (i == 0 && groupQuestion != "") {
            question = groupQuestion;
        }

        string choice1 = xsArrayGetString(choicesArray, i * 2);
        string choice2 = "";
        if ((i * 2) + 1 < size) {
            choice2 = xsArrayGetString(choicesArray, i * 2 + 1);
        }

        xsCreateDecision(player, decisionId, question, choice1, choice2);

        xsArraySetInt(arrActiveDecisionsToGroupMap, decisionId, groupId);
        xsArraySetInt(arrActiveDecisionsToPlayerMap, decisionId, player);
        xsArraySetInt(arrActiveDecisionsToAnswerArrayMap, decisionId, answerArray);
    }

    return (answerArray);
}

rule checkDecisionChoices
    active
    minInterval 1
{
    int size = xsArrayGetSize(arrActiveDecisionsToGroupMap);
    for (decisionId = 0; < size) {
        int groupId = xsArrayGetInt(arrActiveDecisionsToGroupMap, decisionId);
        if (groupId == -1 || groupId >= cMarkForClear) {
            continue;
        }

        int player  = xsArrayGetInt(arrActiveDecisionsToPlayerMap, decisionId);

        int choice = xsGetDecisionChoice(decisionId);
        if (choice == cChoicePending) {
            continue;
        }

        /* Unique per decisionAsk call, so it identifies this specific ask (group + player) */
        int answerArray = xsArrayGetInt(arrActiveDecisionsToAnswerArrayMap, decisionId);

        int decisionsInGroup = 0;
        int decisionOffset = 0;
        /* Find all decisions belonging to this ask and clear them in UI & Mark for clear in array */
        for (decisionId2 = 0; < size) {
            int groupId2 = xsArrayGetInt(arrActiveDecisionsToGroupMap, decisionId2);
            if (groupId2 == -1 || groupId2 >= cMarkForClear) {
                continue;
            }

            /* Prevent the same question (Group) to multiple players from clearing eachother */
            if (xsArrayGetInt(arrActiveDecisionsToAnswerArrayMap, decisionId2) != answerArray) {
                continue;
            }

            xsArraySetInt(arrActiveDecisionsToGroupMap, decisionId2, cMarkForClear);

            xsClearDecision(decisionId2);

            if (decisionId != decisionId2) {
                decisionsInGroup++;
            } else {
                decisionOffset = decisionsInGroup;
            }
        }

        int choicesArray = xsArrayGetInt(arrGroupChoices, groupId);
        int choiceCallbackArray = xsArrayGetInt(arrGroupChoiceCallbacks, groupId);

        /* The amount of groups until the chosen choice was found * 2 (2 per decision) + (choice - 1) for 0 index */
        int choiceIndex = (decisionOffset * 2) + (choice - 1);

        int numberOfChoices = xsArrayGetSize(choicesArray);
        /* The final option was picked from an uneven amount of options, invaled call, pretend it is the one before it */
        if (choiceIndex == numberOfChoices) {
            choiceIndex = numberOfChoices - 1;
        }

        string choiceCallback = xsArrayGetString(choiceCallbackArray, choiceIndex);

        string groupCallback = xsArrayGetString(arrGroupCallbacks, groupId);

        xsArraySetInt(answerArray, 0, groupId);
        xsArraySetInt(answerArray, 1, choiceIndex);
        xsArraySetInt(answerArray, 2, player);

        __callFunc(groupCallback, answerArray);
        __callFunc(choiceCallback, answerArray);
    }
}

/**
 * This ensures it takes a couple seconds before the same IDs can be re-used.
 * After clicking a choice, the game takes 3s to update the UI and remove it.
 */
rule waitForPreviousCleared
    active
    minInterval 1
{
    int size = xsArrayGetSize(arrActiveDecisionsToGroupMap);

    for (decisionId = 0; < size) {
        int groupId = xsArrayGetInt(arrActiveDecisionsToGroupMap, decisionId);
        if (groupId < cMarkForClear) {
            continue;
        }

        if (groupId >= cReadyForDelete) {
            xsArraySetInt(arrActiveDecisionsToGroupMap, decisionId, -1);
            xsArraySetInt(arrActiveDecisionsToPlayerMap, decisionId, -1);
            xsArraySetInt(arrActiveDecisionsToAnswerArrayMap, decisionId, -1);

            continue;
        }

        /* Increase by one */
        xsArraySetInt(arrActiveDecisionsToGroupMap, decisionId, groupId + 1);
    }
}