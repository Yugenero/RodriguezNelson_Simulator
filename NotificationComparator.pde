import java.util.Comparator;

public class NotificationComparator implements Comparator<Notification> {
    
    //@Override
    public int compare(Notification n1, Notification n2) {
      return min(n1.getPriorityLevel(), n2.getPriorityLevel());
    }
}
