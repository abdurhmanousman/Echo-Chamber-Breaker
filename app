import streamlit as st
from google import genai
from google.genai import types
import time

# 1. SETUP & CONFIGURATION
st.set_page_config(page_title="Echo-Chamber Breaker", page_icon="⚖️")
client = genai.Client(api_key=st.secrets["GEMINI_API_KEY"])
MODEL_ID = "gemini-3-flash-preview"

# Define the Google Search Tool for grounding
search_tool = types.Tool(google_search=types.GoogleSearch())

# 2. AGENT DEFINITIONS (The Swarm)
def run_agent(instr, prompt, thinking="medium", tools=None):
    """Helper to call Gemini 3 with specific thinking levels."""
    return client.models.generate_content(
        model=MODEL_ID,
        config=types.GenerateContentConfig(
            system_instruction=instr,
            tools=tools,
            thinking_config=types.ThinkingConfig(include_thoughts=True, thinking_level=thinking)
        ),
        contents=prompt
    )

# 3. STREAMLIT UI LAYOUT
st.title("⚖️ Echo-Chamber Breaker")
st.markdown("### *Track A: Strategic Research Swarm for SDG 16*")

query = st.text_input("Enter a research topic or claim:", 
                     placeholder="e.g., The impact of AI on job markets")

if st.button("Break the Echo Chamber"):
    if query:
        # --- PHASE 1: THE SCOUT ---
        with st.status("Agent 1: Scout gathering mainstream views...", expanded=True):
            scout_instr = "Find and summarize the most popular arguments FOR this claim."
            scout_res = run_agent(scout_instr, query, thinking="low", tools=[search_tool])
            st.write(scout_res.text)
            mainstream_data = scout_res.text

        # --- PHASE 2: THE DISSENTER ---
        with st.status("Agent 2: Dissenter performing deep adversarial research...", expanded=True):
            dissenter_instr = f"Mainstream View: {mainstream_data}. Now, find credible data that CONTRADICTS this."
            # High thinking level is crucial here to force the model out of its comfort zone
            dissenter_res = run_agent(dissenter_instr, query, thinking="high", tools=[search_tool])
            st.write(dissenter_res.text)
            dissent_data = dissenter_res.text

        # --- PHASE 3: THE SYNTHESIZER ---
        with st.status("Agent 3: Synthesizing balanced intelligence briefing...", expanded=True):
            synth_instr = "Create a balanced report. Highlight consensus and critical disagreements."
            final_res = run_agent(synth_instr, f"PRO: {mainstream_data}\nCON: {dissent_data}", thinking="medium")
            
        # 4. FINAL OUTPUT DISPLAY
        st.divider()
        st.subheader("Final Research Briefing")
        st.markdown(final_res.text)
        
        # Show Grounding Sources
        if final_res.candidates[0].grounding_metadata:
            with st.expander("View Verified Sources"):
                st.write(final_res.candidates[0].grounding_metadata.search_entry_point.rendered_content)
    else:
        st.warning("Please enter a topic first!")

# 5. FOOTER
st.info("Built for Gemini Nexus: The Agentverse Hackathon | Supporting SDG 16")
