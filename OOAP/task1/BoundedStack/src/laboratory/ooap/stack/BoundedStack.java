package laboratory.ooap.stack;

public abstract class BoundedStack<T>
{
    //Default stack capacity
    public static final int DEFAULT_CAPACITY = 32;

    //Command status constants
    public static final int PEEK_NIL = 0;
    public static final int PEEK_OK = 1;
    public static final int PEEK_ERR = 2;
    public static final int POP_NIL = 0;
    public static final int POP_OK = 1;
    public static final int POP_ERR = 2;
    public static final int PUSH_NIL = 0;
    public static final int PUSH_OK = 1;
    public static final int PUSH_ERR = 2;

    //Constructors
    public BoundedStack(){} //Default Constructor. Return BoundedStack with default maxCapacity
    public BoundedStack(int maxCapacity){} //Constructor. Return BoundedStack with defined maxCapacity

    //Commands
    public abstract void push(T value); //Precondition: stack has free slot. Postcondition: value added on top of stack.
    public abstract void pop(); //Precondition: stack not empty. Postcondition: first element of the stack deleted.
    public abstract void clear();//Postcondition: all elements of the stack deleted. All statuses set to NIL

    //Requests
    public abstract T peek(); //Precondition: stack not empty. Returns element on head of the stack.
    public abstract int size();
    public abstract int getMaxCapacity();

    public abstract int getPopStatus();
    public abstract int getPeekStatus();
    public abstract int getPushStatus();
}
