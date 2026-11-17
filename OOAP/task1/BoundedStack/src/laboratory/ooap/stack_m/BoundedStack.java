package laboratory.ooap.stack_m;

import java.util.LinkedList;

//Merged version of stack.BoundedStack<T> and stack.BoundedLinkedStack<T>
public class BoundedStack<T>
{
    private LinkedList<T> stack;
    private final int maxCapacity;

    //Commands statuses
    private int peekStatus; //peek status
    private int popStatus; //pop status
    private int pushStatus; //push status

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

    //Default stack capacity
    public static final int DEFAULT_CAPACITY = 32;

    public BoundedStack() //Default Constructor. Return BoundedStack with default maxCapacity
    {
        this.stack = new LinkedList<>();
        this.maxCapacity = DEFAULT_CAPACITY;

        popStatus = POP_NIL;
        peekStatus = PEEK_NIL;
        pushStatus = PUSH_NIL;
    }

    public BoundedStack(int maxCapacity) //Constructor. Return BoundedStack with defined maxCapacity
    {
        this.stack = new LinkedList<>();
        this.maxCapacity = maxCapacity;

        popStatus = POP_NIL;
        peekStatus = PEEK_NIL;
        pushStatus = PUSH_NIL;
    }

    //Commands:
    //Precondition: stack has free slot. Postcondition: value added on top of stack.
    public void push(T value)
    {
        if(size() < maxCapacity)
        {
            stack.push(value);
            pushStatus = PUSH_OK;
        }
        else
        {
            pushStatus = PUSH_ERR;
        }
    }

    //Precondition: stack not empty. Postcondition: first element of the stack deleted.
    public void pop() {
        if(size() > 0)
        {
            stack.pop();
            popStatus = POP_OK;
        }
        else
        {
            popStatus = POP_ERR;
        }
    }

    //Postcondition: all elements of the stack deleted. All statuses set to NIL
    public void clear()
    {
        stack.clear();

        popStatus = POP_NIL;
        peekStatus = PEEK_NIL;
        pushStatus = PUSH_NIL;
    }

    //Requests:
    //Precondition: stack not empty. Returns element on head of the stack.
    public T peek()
    {
        T result = null; //Use default T value
        if(size() > 0)
        {
            result = stack.peek();
            peekStatus = PEEK_OK;
        }
        else
        {
            peekStatus = PEEK_ERR;
        }

        return result;
    }

    public int size()
    {
        return stack.size();
    }

    public int getMaxCapacity()
    {
        return maxCapacity;
    }

    public int getPopStatus()
    {
        return popStatus;
    }

    public int getPeekStatus()
    {
        return peekStatus;
    }

    public int getPushStatus()
    {
        return pushStatus;
    }
}
