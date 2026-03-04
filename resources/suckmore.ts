// Rehost and simplify the Studierendenwerk Darmstadt menu page
import { DOMParser } from "jsr:@b-fuze/deno-dom";

const originalUrl = new URL("https://suckless.org");
const myUrl = new URL("https://suckmore.org");

const redirect = () => {
  console.error("Redirecting to original page");
  return new Response(originalUrl.origin, {
    headers: {
      location: originalUrl.origin,
    },
    status: 307,
  });
};

const hostnameNoSubDomain = (requestedUrl: URL) => {
  let toReturn = "";
  const hostname = requestedUrl.hostname;

  if (hostname.split(".").length >= 3) {
    toReturn =
      hostname.split(".")[hostname.split(".").length - 2] +
      "." +
      hostname.split(".")[hostname.split(".").length - 1];
  } else {
    toReturn = hostname;
  }
  return toReturn;
};

// Process HTML files
const processHTML = (input: string, requestedUrl: URL) => {
  let textData = input;
  textData = textData
    .replaceAll(
      '<span id="headerSubtitle">software that sucks less</span>',
      '<marquee id="headerSubtitle" style="width: auto"><span>software that sucks less</span></marquee>'
    )
    .replaceAll(originalUrl.host, hostnameNoSubDomain(requestedUrl))
    .replaceAll("suckless", "suckmore")
    .replaceAll("gcc", "Java EE 7")
    .replace(/([^a-zA-Z0-9])C(99)?([^a-zA-Z0-9])/g, "$1Java 7$3")
    .replaceAll("source-code repositories", "dropbox folders")
    .replaceAll("source-code repository", "dropbox folder")
    .replaceAll("git repositories", "dropbox folders")
    .replaceAll("git repository", "dropbox folder")
    .replaceAll("git repo", "dropbox folder")
    .replaceAll("git", "dropbox")
    .replaceAll("code quality", "veganism")
    .replaceAll("quality software", "paid software")
    .replaceAll("simplicity, clarity, and frugality", "simplisticness")
    .replaceAll("simple", "simplistic")
    .replaceAll("minimal", "bare")
    .replaceAll("usable", "unusable")
    .replaceAll("the opposite", "exactly this")
    .replaceAll("Unfortunately", "Fortunately")
    .replaceAll("his/her", "it/its")
    .replaceAll("POSIX", "Microsoft POSIX subsystem")
    .replaceAll("München", "Silicon Valley")
    .replaceAll("Germany", "California")
    .replaceAll("Würzburg", "Cupertino")
    .replaceAll("Linux", "WSL")
    .replaceAll("binary", "WASM blob")
    .replaceAll("BSD", "MacOS™️")
    .replaceAll("switch", "hub")
    .replaceAll("wiki page", "Discord channel")
    .replaceAll(" wiki ", " Discord ")
    .replaceAll("programmer", "vibe-coder")
    .replaceAll("hacker", "vibe-coder")
    .replaceAll("computer", "thin client")
    .replaceAll("EUR", "BTC")
    .replaceAll("USD", "DOGE")
    .replaceAll("community", "corporation")
    .replaceAll("vulnerabilities", "CTF challenges")
    .replaceAll("complexity", "simplicity")
    .replaceAll("developer", "agent")
    .replaceAll(" development", " agentic development")
    .replaceAll("IRC", "Telegram")
    .replaceAll(" hacking", " vibing")

    .replace(/mailing[\W\n]*list/gi, "discord server");

  //.replace(/(?<=<p>[^<]*?)m(?=[^<]*?<\/p>)/g, "meow")

  textData = switchWords(textData, "tab", "space");
  textData = switchWords(textData, "individuals", "corporate entities");
  textData = switchWords(textData, " less", " more");
  textData = switchWords(textData, "most", "least");
  textData = switchWords(textData, "consistency", "inconsistency");
  textData = switchWords(textData, "independant", "dependant");
  textData = switchWords(textData, "open source", "proprietary");
  textData = switchWords(textData, "patch", "pull request");
  textData = switchWords(textData, "static linking", "dynamic linking");
  textData = switchWords(textData, "X11", "Wayland");

  //const dom = new DOMParser().parseFromString(textData, "text/html");
  //const processed = dom.querySelector("html")?.outerHTML;

  return textData;
};

// Process CSS files
const processCSS = (input: string, requestedUrl: URL) => {
  let textData = input;
  textData = textData
    .replaceAll("#17a", "#ff149dff")
    .replaceAll("#069", "#ff149dff")
    .replaceAll("#56c8ff", "#ff149dff");

  textData += `
#menu { transform: rotate(-0.5deg); }
p {
  animation: slide-in 10s linear infinite;
  transform-origin: center;}

@keyframes slide-in {
  0% {
    transform: rotate(0deg);
  }
  25% {
    transform: rotate(0.8deg);
  }
  50% {
    transform: rotate(0deg);
  }
  75% {
    transform: rotate(-0.8deg);
  }
  100% {
    transform: rotate(0deg);
  }
}
        `;

  const dom = new DOMParser().parseFromString(textData, "text/html");

  const processed = dom.querySelector("html")?.outerHTML;

  return textData;
};

const PORT = parseInt(Deno.env.get("PORT") || "");
if (!PORT) {
  throw new Error("PORT environment variable is required");
}

const switchWords = (text: string, a: string, b: string) => {
  return text
    .replaceAll(a, "TEMP_PLACEHOLDER")
    .replaceAll(b, a)
    .replaceAll("TEMP_PLACEHOLDER", b);
};

Deno.serve(
  {
    port: PORT,
    hostname: "[::1]",
  },
  async (req) => {
    try {
      const requestedUrl = new URL(req.url);

      const mySubdomain = myUrl.hostname.split(".")[0];
      const requestedSubdomain = requestedUrl.hostname.split(".")[0];
      const subDomainToUse =
        mySubdomain != requestedSubdomain ? requestedSubdomain + "." : "";

      const fullDomainToParse = new URL(
        requestedUrl.protocol +
          "//" +
          subDomainToUse +
          "suckless.org" +
          requestedUrl.pathname +
          requestedUrl.search
      );

      console.log({ fullDomainToParse });
      const textResponse = await fetch(fullDomainToParse.href);

      let processed;
      const fileType = fullDomainToParse.pathname.split(".").pop();

      if (
        fileType == "png" ||
        fileType == "ico" ||
        fileType == "webm" ||
        fileType == "svg" ||
        fileType == "jpg"
      ) {
        processed = await textResponse.blob();
        console.log("didnt process " + fileType);
      } else if (fileType == "css") {
        processed = processCSS(await textResponse.text(), requestedUrl);
        console.log("processed css");
      } else {
        processed = processHTML(await textResponse.text(), requestedUrl);
        console.log("processed html");
      }

      return new Response(processed, {
        headers: {
          "access-control-allow-origin": "*",
          "content-type":
            textResponse.headers.get("content-type") ??
            "text/html; charset=utf-8",

          //for production
          "cache-control": "public, max-age=600",

          //for debugging
          //"cache-control": "no-cache, no-store, must-revalidate",
          pragma: "no-cache",
          expires: "0",
        },
        status: 200,
      });
    } catch (e) {
      console.error(e);
      return redirect();
    }
  }
);
