// Sample JavaScript file for AI code review testing
// This file contains intentional issues to demonstrate AI analysis capabilities

function calculateUserAge(birthYear) {
    // Issue: No input validation
    var currentYear = new Date().getFullYear();
    var age = currentYear - birthYear;
    
    // Issue: Using console.log in production code
    console.log("Calculating age for birth year: " + birthYear);
    
    // Issue: No error handling for invalid dates
    return age;
}

function processUserData(userData) {
    // Issue: Accessing properties without checking if object exists
    var name = userData.name;
    var email = userData.email;
    
    // Issue: Using var instead of const/let
    var isValid = true;
    
    // Issue: Weak email validation
    if (email.includes("@")) {
        console.log("Email seems valid");
    } else {
        isValid = false;
    }
    
    // Issue: Potential type coercion issues
    var age = calculateUserAge(userData.birthYear);
    if (age > "18") {
        userData.isAdult = true;
    }
    
    return {
        name: name,
        email: email,
        age: age,
        isValid: isValid
    };
}

// Issue: Global variable
var globalCounter = 0;

function updateCounter() {
    // Issue: Modifying global state
    globalCounter++;
    return globalCounter;
}

// Issue: Function without proper error handling
async function fetchUserProfile(userId) {
    var response = await fetch("/api/users/" + userId);
    var data = await response.json();
    return data;
}

// Issue: Inefficient array processing
function findUsersByAge(users, targetAge) {
    var result = [];
    for (var i = 0; i < users.length; i++) {
        if (users[i].age == targetAge) {  // Issue: Using == instead of ===
            result.push(users[i]);
        }
    }
    return result;
}