# XsDecisions

An XS script that simplifies, adds choice callbacks and allows multi decision grouping into the XS decisions API

This library has a couple some major advantages over the native decisions API:

1. Allows more than two choices per question
2. Simple choice and question callback functionality instead of ID polling 
3. Easily re-use questions (in decision trees)
4. Remembers answers after decision IDs are re-used
5. Automatic decision ID management (No manual fiddling counters)

## Example usage

The following example shows a simple question asking both player one and player two which civ they'd like to pick. 
Once a choice has been made, the registered callback `onAnswer(...)` is called causing a chat showing the result to be sent. 

```cpp
include "decisions.xs";

void onAnswer(int answerArray = -1) {
    string choice = decisionGetChoice(answerArray);
    int player = decisionGetPlayer(answerArray);
    
    xsChatData(fstr("Player {player} picked: {choice}"));
}

void main() {
    /* Create a question with 5 answers */
    int q = decisionCreateWithChoices("Pick a civ", "Britons|Franks|Mongols|Aztecs|Incas", "onAnswer");
    
    /* Ask player one and player two */
    decisionAsk(q, 1);
    decisionAsk(q, 2);
}
```

![Image showcasing decision with result](assets/images/decision.png)

# Using XsDecisions

## 1. Setting up the script

There's two ways of setting up XsDecisions. You can use either option. 
The main advantage of the "include" method, is being able to replace the file more easily if there are any updates in the future.

### Option A - Using `include`

1. Place the `decisions.xs` file in your XS scripts folder:  
   `C:\Users\<user>\Games\Age of Empires 2 DE\<steamId>\resources\_common\xs\`  
   (Or any other folder in which AoE2 DE will look for scripts)

2. Then add this to the top of your script:
   ```cpp
   include "decisions.xs";
   ```

### Option B - Copy and paste the entire code

Copy and paste the entire content of `decisions.xs` at the top of your XS script.

## 2. Create the questions

Defining a question is simple. You can call the `decisionCreate(...)` function.

```cpp
void main() {
    int q1 = decisionCreate("What is your favourite unit?");
}
```

## 3. Add the choices to the question

There's two ways to add choices to your question, both of them are shown below:

### 3.1 Using `decisionAddChoice(...)`

The most expressive way to add choices to your question is by calling `decisionAddChoice(...)`.

```cpp
void main() {
    int q1 = decisionCreate("What is your favourite unit?");
    decisionAddChoice(q1, "Two Handed Swordsman");
    decisionAddChoice(q1, "Magundai");
    decisionAddChoice(q1, "Siege Onager");
    decisionAddChoice(q1, "Monk");
}
```

### 3.2 Using `decisionCreateWithChoices(...)`

This method creates both the question and the choices in one go. 
It is quicker to write, but can become a bit unreadable with many choices. 

```cpp
void main() {
    int q1 = decisionCreateWithChoices("What is your favourite unit?", "Two Handed Swordsman|Magundai|Siege Onager|Monk");
}

// Or:
    
void main() {
    string choices = "Two Handed Swordsman|Magundai|Siege Onager|Monk";
    int q1 = decisionCreateWithChoices("What is your favourite unit?", choices);
}
```

As you can see, you can separate every choice by a pipe `|` (half of an `or` operator).  

Technically you could even combine `decisionCreateWithChoices(...)` and then still calling `decisionAddChoice(...)` 
though it is not recommend due to readability. 

## 4. Working with answers

There's again a couple of ways to work with the answers the players give. All of them are described below.
Note that the callbacks below are _not_ populated with anything useful. 
Please see the header below for more information on callback functionality. 

It is also possible to combine any of the callback options below. 
You can safely add a choice callback, question callback and Question ID polling together on a single question.
The order in which the callbacks are called in are question callback first, choice callback second.  

### 4.1 Choice Callbacks

For every choice you add you can add a "callback".
A callback is a function that is called automatically upon a player clicking the corresponding choice.

Below you can see multiple ways to set a choice callback and how to use them:

#### 4.1.1 Choice callback on `decisionAddChoice(...)`

With the example below you can see how a question has two answers, both have their own callback.
When `Yes` is clicked, a chat message will be sent: `The answer is: YES`.

```cpp
void onYes(int answerArray = -1) {
    // Actually useful functions for within a callback can be found at the next header
    xsChatData("The answer is: YES");  
}

void onNo(int answerArray = -1) {
    // Actually useful functions for within a callback can be found at the next header
    xsChatData("The answer is: NO");  
}

void main() {
    int q1 = decisionCreate("Do you want to trade gold?");
    decisionAddChoice(q1, "Yes", "onYes");
    decisionAddChoice(q1, "No", "onNo");
}
```

#### 4.1.2 Choice callback on `decisionCreateWithChoices(...)`

This is a shorthand for the above. You can use `:::` to add a callback to a choice.
You might be able to tell why this style is not recommended for larger questions. It is _very_ verbose.

```cpp
/* Also needs `onYes(...)` and `onNo(...)` from the above code block */

void main() {
    int q1 = decisionCreateWithChoices("Do you want to trade gold?", "Yes:::onYes|No:::onNo");
}
```

### 4.2 Question Callbacks

Like choices, callbacks can also be added to questions.
This means this callback is called no matter which choice 

-- wip --

### 4.3 Question ID Polling

-- wip --

## 5. Callback functionality

-- wip --