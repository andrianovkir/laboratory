package linked_list;

import java.util.Collection;

public abstract class CursoredLinkedList<T>
{
    public static final int GET_STATUS_OK = 1;
    public static final int GET_STATUS_ERR = 2;
    public static final int PUT_STATUS_OK = 1;
    public static final int PUT_STATUS_ERR = 2;
    public static final int REMOVE_STATUS_OK = 1;
    public static final int REMOVE_STATUS_ERR = 2;
    public static final int FIND_STATUS_OK = 1;
    public static final int FIND_STATUS_ERR = 2;

    public CursoredLinkedList(){} //Constructor. Returns new empty LinkedList

    //List Commands
    //Preconditions : list not empty. Cursor set on some value.
    //Postconditions: -
    public abstract T get();
    //Preconditions : list not empty. Cursor set on some value.
    //Postconditions: value added to List before cursor.
    public abstract void putLeft(T value);
    //Preconditions : list not empty. Cursor set on some value.
    //Postconditions: value added to List after cursor.
    public abstract void putRight(T value);
    //Preconditions : list is empty.
    //Postconditions: value added to List. Cursor set to value
    public abstract void putToEmpty(T value);
    //Preconditions : list not empty. Cursor set on some value.
    //Postconditions: value on cursor replaced by received value.
    public abstract void replace(T value);
    //Preconditions : list not empty. Cursor set on some value.
    //Postconditions: current element deleted. Cursor set to right neighbor if possible.
    public abstract void remove();
    //Preconditions : list not empty.
    //Postconditions: Deleted first entry of value. Cursor set to its right neighbor if possible.
    public abstract void remove(T value);
    //Preconditions : list not empty.
    //Postconditions: Deleted all entries of value. Cursor set to lasts right neighbor if possible.
    public abstract void removeAll(T value);
    //Preconditions : -
    //Postconditions: list is empty. Cursor is undefined.
    public abstract void clear();

    //Cursor commands (not affect on List):
    //Preconditions : list not empty.
    public abstract void head();
    //Preconditions : list not empty.
    public abstract void tail();
    //Preconditions : list not empty.
    public abstract void next();
    //Preconditions : list not empty.
    public abstract void find(T value);

    //Requests List
    //Precondition: -
    public abstract boolean size();
    //Precondition: -
    public abstract int getLastGetStatus();
    //Precondition: -
    public abstract int getLastPutStatus();
    //Precondition: -
    public abstract int getLastRemoveStatus();
    //Precondition: -
    public abstract int getLastFindStatus();

    //Requests Cursor
    //Precondition: list not empty
    public abstract boolean isHead();
    //Precondition: list not empty
    public abstract boolean isTail();
    //Precondition: list not empty
    public abstract boolean isValue();
}
