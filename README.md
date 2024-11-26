* * * * *

Report: Reddit Simulation Using Protoactor-Go
=============================================

Overview
--------

This project is a simulation of a simplified Reddit platform implemented using the **actor model** via the `protoactor-go` library. The system models various user interactions, such as posting, commenting, upvoting, and downvoting, while leveraging concurrency to simulate multiple users performing actions simultaneously. The project demonstrates the efficiency and fault tolerance of the actor model in handling distributed tasks.

* * * * *

Code Explanation
----------------

### 1\. **`main.go`**

This file serves as the entry point of the application, performing the following tasks:

1.  **Initialize Actor System**: The `protoactor-go` library is used to create an `ActorSystem`. This system serves as the framework for managing actors and their interactions.

2.  **Spawn the `RedditEngine` Actor**:

    -   A `RedditEngine` actor is initialized and spawned. This actor is responsible for managing the core simulation, including users, subreddits, posts, and votes.
    -   The actor system assigns a **Process ID (PID)** to the `RedditEngine`, enabling communication.
3.  **Simulate User Interactions**:

    -   The simulation involves `numUsers = 10` users performing actions such as registering, posting, commenting, and voting.
    -   Each user's actions are simulated in a separate goroutine, allowing concurrent execution.
4.  **Synchronization**:

    -   A `sync.WaitGroup` is used to ensure all user actions complete before the program exits.

* * * * *

### 2\. **`Simulation (1).go`**

This file defines the logic for simulating user behavior and their interactions with the system.

#### Key Functions:

1.  **`SimulateUser`**:

    -   Simulates the actions of a user, including:
        -   Registering and joining subreddits.
        -   Creating posts and comments.
        -   Sending and replying to messages.
        -   Upvoting and downvoting posts.
    -   Actions are randomized to mimic real-world variability.
2.  **Message Passing**:

    -   Uses defined protocol messages like `RegisterUser`, `CreatePost`, and `VotePost` to interact with the `RedditEngine` actor.
    -   This ensures strict decoupling between the simulation logic and the actor system.

* * * * *

### 3\. **`UpDownVote.go`**

This file implements the upvote and downvote functionality for posts.

#### Key Functions:

1.  **`UpvoteRandomPost`**:

    -   Checks if the user exists and is subscribed to a subreddit.
    -   Randomly selects a post from the user's subscribed subreddits and increments its upvote count.
    -   Updates the post creator's karma points.
2.  **`DownvoteRandomPost`**:

    -   Similar logic to upvoting but decrements the upvote count and karma points.
    -   Handles edge cases, such as ensuring votes cannot go below zero.

* * * * *

How the System Works
--------------------

1.  **Actor Model**:

    -   Actors are lightweight, independent units of computation.
    -   The `RedditEngine` actor encapsulates all data and logic, communicating via asynchronous messages.
2.  **Concurrency**:

    -   Users' actions are simulated concurrently using Go's goroutines.
    -   Synchronization mechanisms (e.g., `sync.WaitGroup`) are used to manage parallel execution.
3.  **Randomized Actions**:

    -   To simulate diverse and realistic behavior, actions such as subreddit selection, post creation, and voting are randomized.
4.  **Error Handling**:

    -   The system ensures robustness by validating user and post existence before performing actions like voting.

* * * * *

How to Run the Project
----------------------

### Prerequisites

1.  **Install Go**:

    -   Ensure Go is installed on your system. You can download it from [golang.org](https://golang.org/).
2.  **Install Dependencies**:

    -   Install the `protoactor-go` library:

        ```
        go get github.com/asynkron/protoactor-go/actor

        ```

### Steps to Run

1.  **Clone the Repository**:

    -   Clone the project repository to your local machine:

        ```
        git clone <repository-url>
        cd <project-directory>

        ```

2.  **Run the Application**:

    -   Execute the main file:

        ```
        go run main.go

        ```

### Expected Output

-   The application initializes the actor system and simulates 10 users performing actions.
-   You will see logs of user actions, such as:

    ```
    ActorSystem created
    RedditEngine initialized
    User1 created a post in subreddit golang.
    User2 upvoted post ID 1 in subreddit golang.
    Updated karma for user1. New Post Karma: 10
    Finished simulating all users.

    ```

* * * * *

Conclusion
----------

This project demonstrates the use of the actor model to build a robust, concurrent simulation of a Reddit-like platform. By leveraging `protoactor-go`, the system ensures modularity, scalability, and fault tolerance. Future enhancements could include persistent storage, moderation features, and visualizations of the simulation process.