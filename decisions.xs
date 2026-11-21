/*
 * ##########################################################
 *    __  __      ____
 *    \ \/ /___  |  _ \  ___  ___(_)___(_) ___  _ __  ___
 *     \  // __| | | | |/ _ \/ __| / __| |/ _ \| '_ \/ __|
 *     /  \\__ \ | |_| |  __/ (__| \__ \ | (_) | | | \__ \
 *    /_/\_\___/ |____/ \___|\___|_|___/_|\___/|_| |_|___/
 *
 * ##########################################################
 *
 * Created by MrKirby -- https://github.com/KSneijders/XsDecisions
 * Version: 1.0.0 (2026-11-14)
 *
 * ######################## Credits #########################
 * XS-Check by Alian -- https://github.com/Divy1211/xs-check
 * Ascii art by: https://patorjk.com/software/taag [Standard]
 * ##########################################################
 */

int arrQuestionChoices = -1;
int arrQuestionChoiceCallbacks = -1;
int arrQuestionTexts = -1;
int arrQuestionCallbacks = -1;

int arrActiveDecisionIds = -1;
int arrActiveDecisionsToQuestionMap = -1;
int arrActiveDecisionsToPlayerMap = -1;
int arrActiveDecisionsToAnswerArrayMap = -1;

bool DECISION_LOGGING_ENABLED = false;

int cMarkForClear = 999999996;
int cReadyForDelete = 999999999;

int cChoicePending = 0;

/* #############################################################
######################### INTERNAL API #########################
############################################################# */

void initializeDecisions__decisions() {
    if (arrActiveDecisionsToQuestionMap != -1) {
        return;
    }

    int activeDecisionsSupportCount = 20;  /* Is expanded automatically */
    arrActiveDecisionIds = xsArrayCreateInt(activeDecisionsSupportCount, -1);
    arrActiveDecisionsToQuestionMap = xsArrayCreateInt(activeDecisionsSupportCount, -1);
    arrActiveDecisionsToPlayerMap = xsArrayCreateInt(activeDecisionsSupportCount, -1);
    arrActiveDecisionsToAnswerArrayMap = xsArrayCreateInt(activeDecisionsSupportCount, -1);

    int questionSupportCount = 5;  /* Is expanded automatically */
    arrQuestionTexts = xsArrayCreateString(questionSupportCount, "");
    arrQuestionCallbacks = xsArrayCreateString(questionSupportCount, "");
    arrQuestionChoices = xsArrayCreateInt(questionSupportCount, -1);
    arrQuestionChoiceCallbacks = xsArrayCreateInt(questionSupportCount, -1);
}

mutable int findIndexString(int arrayId = -1, string match = "") {
    for(i = 0; < xsArrayGetSize(arrayId)) {
        if (xsArrayGetString(arrayId, i) == match) {
            return (i);
        }
    }

    return (-1);
}

mutable int findIndexInt(int arrayId = -1, int match = -1) {
    for(i = 0; < xsArrayGetSize(arrayId)) {
        if (xsArrayGetInt(arrayId, i) == match) {
            return (i);
        }
    }

    return (-1);
}

mutable bool isIntIn(int arrayId = -1, int match = -1) {
    return (findIndexInt(arrayId, match) != -1);
}

mutable void log__decision(string str = "") {
    if (DECISION_LOGGING_ENABLED == false) {
        return;
    }

    xsChatData("[Decisions] " + str);
}

void arrayResizeIntArrayWithDef__decisions(int arr = -1, int def = -1) {
    int oldSize = xsArrayGetSize(arr);

    xsArrayResizeInt(arr, oldSize * 2);
    for (i = oldSize; < oldSize * 2) {
        xsArraySetInt(arr, i, def);
    }
}

void arrayResizeStringArrayWithDef__decisions(int arr = -1, string def = "") {
    int oldSize = xsArrayGetSize(arr);

    xsArrayResizeString(arr, oldSize * 2);
    for (i = oldSize; < oldSize * 2) {
        xsArraySetString(arr, i, def);
    }
}

/**
 * Check if any decision of an ask was clicked, including clicks not yet processed by `checkDecisionChoices__decisions`.
 * The IDs of answered decisions must not be freed early, as this bugs the game.
 */
bool isAnswered__decisions(int answerArray = -1) {
    int size = xsArrayGetSize(arrActiveDecisionIds);
    for (i = 0; < size) {
        if (xsArrayGetInt(arrActiveDecisionsToAnswerArrayMap, i) != answerArray) {
            continue;
        }

        /* Answered and waiting for the game to remove it */
        if (xsArrayGetInt(arrActiveDecisionsToQuestionMap, i) >= cMarkForClear) {
            return (true);
        }

        /* Answered, but not yet processed */
        if (xsGetDecisionChoice(xsArrayGetInt(arrActiveDecisionIds, i)) != cChoicePending) {
            return (true);
        }
    }

    return (false);
}

void callFunc__decisions(string callable = "", int arg = -1) {
    if (callable == "") {
        return;
    }

    xsAddRuntimeEvent("Scenario Triggers", callable, arg);
    xsAddRuntimeEvent("Random Map", callable, arg);
}

/* #############################################################
########################## PUBLIC API ##########################
############################################################# */

/** Check if a decision has been answered. Can be called on the returning int from `decisionAsk(...)` */
bool decisionWasMade(int answerArray = -1) {
    if (answerArray == -1) {
        return (false);
    }

    return (xsArrayGetInt(answerArray, 0) != -1 && xsArrayGetInt(answerArray, 1) != -1);
}

/**
 * Get the player to who this question was asked.
 *
 * Note: When decisionAsk(...) is called with player = -1 (Officially not supported by AoE2) this will return player = -1
 */
int decisionGetPlayer(int answerArray = -1) {
    if (answerArray == -1) {
        return (-1);
    }

    return (xsArrayGetInt(answerArray, 2));
}

/** Get the choice that was made as string. The literal choice string is returned */
string decisionGetChoice(int answerArray = -1) {
    if (answerArray == -1) {
        return ("");
    }

    int questionId = xsArrayGetInt(answerArray, 0);
    int choiceIndex = xsArrayGetInt(answerArray, 1);

    int choicesArray = xsArrayGetInt(arrQuestionChoices, questionId);

    return (xsArrayGetString(choicesArray, choiceIndex));
}

/** Get the question ID returned from `decisionCreate(...)` functions */
int decisionGetQuestion(int answerArray = -1) {
    if (answerArray == -1) {
        return (-1);
    }

    return (xsArrayGetInt(answerArray, 0));
}

/** Get the choice that was made as int representing the index of the choice. Choices are 0-indexed */
int decisionGetChoiceIndex(int answerArray = -1) {
    if (answerArray == -1) {
        return (-1);
    }

    return (xsArrayGetInt(answerArray, 1));
}

/**
 * Create a new question without choices. Add choices using `decisionAddChoice(...)`.
 * Returns the question ID which can be passed to `decisionAsk(...)`.
 *
 * The callback is the name of a function `void name(int answerArray = -1)` which is called when any choice is made.
 *
 * The callback function MUST HAVE a single int argument, no more, no less!
 */
int decisionCreate(string question = "", string callback = "") {
    initializeDecisions__decisions();

    int questionId = findIndexInt(arrQuestionChoices, -1);
    if (questionId == -1) {
        arrayResizeStringArrayWithDef__decisions(arrQuestionTexts);
        arrayResizeStringArrayWithDef__decisions(arrQuestionCallbacks);
        arrayResizeIntArrayWithDef__decisions(arrQuestionChoices);
        arrayResizeIntArrayWithDef__decisions(arrQuestionChoiceCallbacks);

        questionId = findIndexInt(arrQuestionChoices, -1);
    }

    xsArraySetInt(arrQuestionChoices, questionId, xsArrayCreateString(4, ""));
    xsArraySetInt(arrQuestionChoiceCallbacks, questionId, xsArrayCreateString(4, ""));

    xsArraySetString(arrQuestionTexts, questionId, question);
    xsArraySetString(arrQuestionCallbacks, questionId, callback);

    log__decision("Created question " + questionId + ": '" + question + "' (callback: '" + callback + "')");

    return (questionId);
}

/**
 * Add a choice to a question created by `decisionCreate(...)`. Choices are shown in the order they are added.
 *
 * The callback is the name of a function `void name(int answerArray = -1)` which is called only when this choice is made.
 * If the question also has a callback, the question callback is called first.
 *
 * The callback functions MUST HAVE a single int argument, no more, no less!
 *
 * Note: Both questionId and choice are required arguments
 *
 * @allow_discard
 */
int decisionAddChoice(int questionId = -1, string choice = "", string callback = "") {
    if (questionId == -1 || choice == "") {
        return (-1);
    }

    int choicesArray = xsArrayGetInt(arrQuestionChoices, questionId);
    int choiceCallbackArray = xsArrayGetInt(arrQuestionChoiceCallbacks, questionId);

    int choiceIndex = findIndexString(choicesArray, "");

    if (choiceIndex == -1) {
        arrayResizeStringArrayWithDef__decisions(choicesArray);
        arrayResizeStringArrayWithDef__decisions(choiceCallbackArray);

        choiceIndex = findIndexString(choicesArray, "");
    }

    xsArraySetString(choicesArray, choiceIndex, choice);
    xsArraySetString(choiceCallbackArray, choiceIndex, callback);

    log__decision("Added choice " + choiceIndex + " to question " + questionId + ": '" + choice + "' (callback: '" + callback + "')");

    return (choiceIndex);
}

/**
 * Create a new question with all choices at once. Returns the question ID which can be passed to `decisionAsk(...)`.
 *
 * Choices are separated by `|`. A choice callback can be added using `:::`, for example: "Yes:::onYes|No:::onNo"
 * The callback is called when any choice is made (See `decisionCreate(...)`)
 *
 * The callback functions MUST HAVE a single int argument, no more, no less!
 *
 * Note: Choices cannot contain `|` or `:::`
 */
int decisionCreateWithChoices(string question = "", string pipeSeparatedChoices = "", string callback = "") {
    int choices = strSplit(pipeSeparatedChoices, "|");

    string choice = "";
    string choiceCallback = "";

    int questionId = decisionCreate(question, callback);
    for (i = 0; < xsArrayGetSize(choices)) {
        choice = xsArrayGetString(choices, i);
        choiceCallback = "";

        if (strContains(choice, ":::")) {
            int choiceSegments = strSplit(choice, ":::");
            choice = xsArrayGetString(choiceSegments, 0);
            choiceCallback = xsArrayGetString(choiceSegments, 1);
        }

        decisionAddChoice(questionId, choice, choiceCallback);
    }

    return (questionId);
}

/**
 * Show a question to a player. Every 2 choices are shown as a separate decision, the question text is only shown on the first.
 * Returns an answer array which can be used with `decisionWasMade(...)` and the other getters, or -1 if it failed.
 *
 * The same question can be asked to multiple players (or multiple times) at once, each ask is answered separately
 *
 * @allow_discard
 */
int decisionAsk(int questionId = -1, int player = -1) {
    if (questionId == -1) {
        return (-1);
    }

    string questionText = xsArrayGetString(arrQuestionTexts, questionId);

    int choicesArray = xsArrayGetInt(arrQuestionChoices, questionId);
    int choiceCallbackArray = xsArrayGetInt(arrQuestionChoiceCallbacks, questionId);

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

    /* Find the first range of consecutive Decision IDs which are not in use */
    int decisionStartId = 0;
    int consecEmpty = 0;  /* Consecutive Empty IDs */
    while (consecEmpty < numberOfDecisions) {
        if (isIntIn(arrActiveDecisionIds, decisionStartId + consecEmpty)) {
            decisionStartId = decisionStartId + consecEmpty + 1;
            consecEmpty = 0;
        } else {
            consecEmpty++;
        }
    }

    log__decision("Asking question " + questionId + " to player " + player + " using decision IDs " + decisionStartId + "-" + (decisionStartId + numberOfDecisions - 1));

    int answerArray = xsArrayCreateInt(3, -1);

    for (i = 0; < numberOfDecisions) {
        int decisionId = decisionStartId + i;

        int arrIndex = findIndexInt(arrActiveDecisionIds, -1);
        if (arrIndex == -1) {
            arrayResizeIntArrayWithDef__decisions(arrActiveDecisionIds);
            arrayResizeIntArrayWithDef__decisions(arrActiveDecisionsToQuestionMap);
            arrayResizeIntArrayWithDef__decisions(arrActiveDecisionsToPlayerMap);
            arrayResizeIntArrayWithDef__decisions(arrActiveDecisionsToAnswerArrayMap);

            arrIndex = findIndexInt(arrActiveDecisionIds, -1);
        }

        string question = "";
        if (i == 0 && questionText != "") {
            question = questionText;
        }

        string choice1 = xsArrayGetString(choicesArray, i * 2);
        string choice2 = "";
        if ((i * 2) + 1 < size) {
            choice2 = xsArrayGetString(choicesArray, i * 2 + 1);
        }

        xsCreateDecision(player, decisionId, question, choice1, choice2);

        xsArraySetInt(arrActiveDecisionIds, arrIndex, decisionId);
        xsArraySetInt(arrActiveDecisionsToQuestionMap, arrIndex, questionId);
        xsArraySetInt(arrActiveDecisionsToPlayerMap, arrIndex, player);
        xsArraySetInt(arrActiveDecisionsToAnswerArrayMap, arrIndex, answerArray);
    }

    return (answerArray);
}

/**
 * Remove a pending question from the player's screen. Can be called on the returning int from `decisionAsk(...)`
 * Returns true if the question was cleared, false if there was nothing to clear.
 *
 * Questions that were already answered cannot be cleared, they are removed automatically.
 * After clearing, no callbacks are called and `decisionWasMade(...)` remains false.
 *
 * @allow_discard
 */
bool decisionClear(int answerArray = -1) {
    if (answerArray == -1 || isAnswered__decisions(answerArray)) {
        return (false);
    }

    bool cleared = false;
    int size = xsArrayGetSize(arrActiveDecisionIds);
    for (i = 0; < size) {
        if (xsArrayGetInt(arrActiveDecisionsToAnswerArrayMap, i) != answerArray) {
            continue;
        }

        xsClearDecision(xsArrayGetInt(arrActiveDecisionIds, i));

        xsArraySetInt(arrActiveDecisionIds, i, -1);
        xsArraySetInt(arrActiveDecisionsToQuestionMap, i, -1);
        xsArraySetInt(arrActiveDecisionsToPlayerMap, i, -1);
        xsArraySetInt(arrActiveDecisionsToAnswerArrayMap, i, -1);

        cleared = true;
    }

    if (cleared) {
        log__decision("Cleared answer array " + answerArray);
    }

    return (cleared);
}

/* #############################################################
######################## INTERNAL RULES ########################
############################################################# */

rule checkDecisionChoices__decisions
    active
    minInterval 1
{
    int size = xsArrayGetSize(arrActiveDecisionIds);
    int decisionId = -1;
    for (i = 0; < size) {
        decisionId = xsArrayGetInt(arrActiveDecisionIds, i);
        if (decisionId == -1) {
            continue;
        }

        int questionId = xsArrayGetInt(arrActiveDecisionsToQuestionMap, i);
        if (questionId == -1 || questionId >= cMarkForClear) {
            continue;
        }

        int player  = xsArrayGetInt(arrActiveDecisionsToPlayerMap, i);

        int choice = xsGetDecisionChoice(decisionId);
        if (choice == cChoicePending) {
            continue;
        }

        /* Unique per decisionAsk call, so it identifies this specific ask (question + player) */
        int answerArray = xsArrayGetInt(arrActiveDecisionsToAnswerArrayMap, i);

        int decisionsInQuestion = 0;
        int decisionOffset = 0;
        /* Find all decisions belonging to this ask and clear them in UI & Mark for clear in array */
        for (j = 0; < size) {
            int decisionId2 = xsArrayGetInt(arrActiveDecisionIds, j);
            if (decisionId2 == -1) {
                continue;
            }

            int questionId2 = xsArrayGetInt(arrActiveDecisionsToQuestionMap, j);
            if (questionId2 == -1 || questionId2 >= cMarkForClear) {
                continue;
            }

            /* Prevent the same question to multiple players from clearing eachother */
            if (xsArrayGetInt(arrActiveDecisionsToAnswerArrayMap, j) != answerArray) {
                continue;
            }

            xsArraySetInt(arrActiveDecisionsToQuestionMap, j, cMarkForClear);

            xsClearDecision(decisionId2);

            if (decisionId != decisionId2) {
                decisionsInQuestion++;
            } else {
                decisionOffset = decisionsInQuestion;
            }
        }

        int choicesArray = xsArrayGetInt(arrQuestionChoices, questionId);
        int choiceCallbackArray = xsArrayGetInt(arrQuestionChoiceCallbacks, questionId);

        /* The amount of decisions before the chosen one * 2 (2 per decision) + (choice - 1) for 0 index */
        int choiceIndex = (decisionOffset * 2) + (choice - 1);

        int numberOfChoices = xsArrayGetSize(choicesArray);
        /* The final option was picked from an uneven amount of options, invaled call, pretend it is the one before it */
        if (choiceIndex == numberOfChoices) {
            choiceIndex = numberOfChoices - 1;
        }

        string choiceCallback = xsArrayGetString(choiceCallbackArray, choiceIndex);

        string questionCallback = xsArrayGetString(arrQuestionCallbacks, questionId);

        xsArraySetInt(answerArray, 0, questionId);
        xsArraySetInt(answerArray, 1, choiceIndex);
        xsArraySetInt(answerArray, 2, player);

        log__decision("Player " + player + " chose '" + xsArrayGetString(choicesArray, choiceIndex) + "' (index " + choiceIndex + ") for question " + questionId);

        callFunc__decisions(questionCallback, answerArray);
        callFunc__decisions(choiceCallback, answerArray);
    }
}

/**
 * This ensures it takes a couple seconds before the same IDs can be re-used.
 * After clicking a choice, the game takes 3s to update the UI and remove it.
 */
rule waitForPreviousCleared__decisions
    active
    minInterval 1
{
    int size = xsArrayGetSize(arrActiveDecisionsToQuestionMap);
    for (i = 0; < size) {
        int questionId = xsArrayGetInt(arrActiveDecisionsToQuestionMap, i);
        if (questionId < cMarkForClear) {
            continue;
        }

        if (questionId >= cReadyForDelete) {
            log__decision("Decision ID " + xsArrayGetInt(arrActiveDecisionIds, i) + " released (slot " + i + ")");

            xsArraySetInt(arrActiveDecisionIds, i, -1);
            xsArraySetInt(arrActiveDecisionsToQuestionMap, i, -1);
            xsArraySetInt(arrActiveDecisionsToPlayerMap, i, -1);
            xsArraySetInt(arrActiveDecisionsToAnswerArrayMap, i, -1);

            continue;
        }

        /* Increase by one */
        xsArraySetInt(arrActiveDecisionsToQuestionMap, i, questionId + 1);
    }
}

/* #############################################################
############## END OF XS-DECISIONS ### By MrKirby ##############
############################################################# */
