// Rehost and simplify the Studierendenwerk Darmstadt menu page
import { DOMParser } from "jsr:@b-fuze/deno-dom";

const originalUrl =
  "https://studierendenwerkdarmstadt.de/hochschulgastronomie/speisen/stadtmitte/";

const redirect = () => {
  console.error("Redirecting to original page");
  return new Response(originalUrl, {
    headers: {
      location: originalUrl,
    },
    status: 307,
  });
};

const PORT = parseInt(Deno.env.get("PORT") || "");
if (!PORT) {
  throw new Error("PORT environment variable is required");
}

Deno.serve(
  {
    port: PORT,
    hostname: "[::1]",
  },
  async (_req) => {
    try {
      const textResponse = await fetch(originalUrl);
      const textData = await textResponse.text();

      let dom = new DOMParser().parseFromString(textData, "text/html");

      dom.querySelector("#borlabs-cookie-css")?.remove();
      dom.querySelector("#borlabs-cookie-js-extra")?.remove();
      dom.querySelector("#borlabs-cookie-prioritize-js-extra")?.remove();
      dom.querySelector("#borlabs-cookie-prioritize-js")?.remove();
      dom.querySelector("#BorlabsCookieBoxWrap")?.remove();
      dom.querySelector("#page-bg-css")?.remove();
      dom.querySelector("#borlabs-cookie-js-after")?.remove();
      dom.querySelector("#borlabs-cookie-js")?.remove();
      dom.querySelector(".max")?.remove();
      dom.querySelector(".max")?.remove();
      dom.querySelector(".max")?.remove();
      dom.querySelector("header")?.remove();
      dom.querySelector(".footer-info")?.remove();
      dom.querySelector("#menu-footer-menu")?.remove();

      dom.querySelector("#wpml-legacy-dropdown-0-js")?.remove();
      dom.querySelector("#wp-hooks-js")?.remove();
      dom.querySelector("#wp-i18n-js")?.remove();
      dom.querySelector("#swv-js")?.remove();
      dom.querySelector("#contact-form-7-js")?.remove();
      dom.querySelector("#js-cookie-js")?.remove();
      dom.querySelector("#imagesloaded-js")?.remove();
      dom.querySelector("#picturefill-js")?.remove();
      dom.querySelector("#wpcf7cf-scripts-js")?.remove();
      dom.querySelector("#smush-lazy-load-js")?.remove();

      dom.querySelector("#wp-i18n-js-after")?.remove();
      dom.querySelector("#contact-form-7-js-translations")?.remove();
      dom.querySelector("#contact-form-7-js-before")?.remove();
      dom.querySelector("#wpcf7cf-scripts-js-extra")?.remove();

      dom.querySelector("#neosmart-atomic-fonts-css")?.remove();

      let scripts = dom.querySelectorAll("script");
      scripts.forEach((script) => {
        const requiredScripts = [
          "jquery-core-js",
          "neosmart-atomic-scripts-js",
        ];
        if (!requiredScripts.includes(script.getAttribute("id") || "")) {
          script.remove();
          return;
        }
      });
      scripts = dom.querySelectorAll("script");
      for (const script of scripts) {
        console.log(script.getAttribute("src"));
        const src = script.getAttribute("src");
        if (!src) {
          continue;
        }
        try {
          const response = await fetch(src);
          const text = await response.text();
          script.innerHTML = text;
          script.removeAttribute("src");
        } catch (_) {
          return redirect();
        }
      }

      const styles = dom.querySelectorAll('link[rel="stylesheet"]');
      for (const style of styles) {
        console.log(style.getAttribute("href"));
        const src = style.getAttribute("href");
        if (!src) {
          continue;
        }
        const response = await fetch(src);
        const text = await response.text();
        const newStyle = dom.createElement("style");
        newStyle.innerHTML = text;
        newStyle.setAttribute("type", "text/css");
        newStyle.setAttribute("id", style.getAttribute("id") || undefined);
        style.replaceWith(newStyle);
      }

      const wrap = dom.querySelector(".wrap");
      const content = dom.querySelector(".main");
      if (!wrap || !content) {
        return redirect();
      }
      wrap.replaceWith(content);

      const body = dom.querySelector("body");
      if (!body) {
        return redirect();
      }
      body.setAttribute("style", "padding: 0.5rem;");

      // // Fix link in download button
      // let downloadButton = dom.querySelector("a[href='.?pdf=1']");
      // if (downloadButton) {
      //   downloadButton.setAttribute(
      //     "href",
      //     `${originalUrl}/?pdf=1`
      //   );
      // }
      // Remove download button because it's broken
      body.querySelector(".fmc-menu-download")?.remove();

      // Patch styling
      content
        .querySelector("h2")
        ?.setAttribute(
          "style",
          "margin-top: 0.5rem; margin-bottom: 0.5rem; text-align: center;"
        );

      const processed = dom.querySelector("html")?.outerHTML;

      return new Response(processed, {
        headers: {
          "content-type": "text/html; charset=utf-8",
          "cache-control": "public, max-age=600",
        },
        status: 200,
      });
    } catch (e) {
      console.error(e);
      return redirect();
    }
  }
);
