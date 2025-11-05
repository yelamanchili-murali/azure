package mry.azuredemos.academo;

import jakarta.servlet.http.HttpSession;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.net.InetAddress;
import java.util.Map;

@RestController
public class AffinityDemoController {

    @GetMapping("/whoami")
    public Map<String, Object> whoami(HttpSession httpSession) throws Exception {
        String host = InetAddress.getLocalHost().getHostName();
        System.out.println("Request served by host: " + host);
        Integer hits = (Integer) httpSession.getAttribute("hits");
        System.out.println("Current hits in this session: " + hits);
        hits = (hits == null) ? 1 : hits + 1;
        System.out.println("Updated hits in this session: " + hits);
        httpSession.setAttribute("hits", hits);
        System.out.println("Session ID: " + httpSession.getId());

        Map<String , Object> responseData = Map.of(
                "host", host,
                "sessionId", httpSession.getId(),
                "hitsCountInThisSession", hits
        );

        return responseData;
    }
}
